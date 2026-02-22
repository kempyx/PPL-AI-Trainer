#!/usr/bin/env python3
"""
Prepare a source dataset (SQLite + images) for PPLAITrainer import.

This script can:
1) extract from a zip package,
2) validate required schema compatibility,
3) normalize EASA top-level category IDs to app-canonical IDs (optional),
4) copy the SQLite and images into app resource folders,
5) report missing attachment files.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import sqlite3
import zipfile


REQUIRED_TABLE_COLUMNS: dict[str, set[str]] = {
    "questions": {
        "id",
        "category",
        "code",
        "text",
        "correct",
        "incorrect0",
        "incorrect1",
        "incorrect2",
        "explanation",
        "reference",
        "attachments",
        "mockonly",
    },
    "categories": {
        "id",
        "parent",
        "quantityinmock",
        "code",
        "name",
        "categorygroup",
        "sortorder",
        "locked",
    },
    "attachments": {"id", "name", "filename", "explanation"},
    "category_groups": {"id", "name"},
}


# App-canonical top-level IDs used by existing study/mock-exam/gamification logic.
EASA_CANONICAL_TOP_LEVEL_ID_BY_CODE: dict[str, int] = {
    "10": 551,  # Air Law
    "21": 560,  # AGK
    "22": 528,  # Instrumentation
    "31": 557,  # Mass and Balance
    "32": 558,  # Performance
    "33": 559,  # Flight Planning
    "40": 552,  # Human Performance
    "50": 553,  # Meteorology
    "61": 501,  # Navigation
    "62": 500,  # Radio Navigation
    "70": 556,  # Operational Procedures
    "81": 555,  # Principles of Flight
    "91": 554,  # Communications
}


IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".gif"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Prepare and normalize dataset resources.")
    parser.add_argument("--source-zip", type=Path, help="Input zip containing sqlite and images.")
    parser.add_argument("--source-db", type=Path, help="Input sqlite path (if not extracting from zip).")
    parser.add_argument("--source-images-dir", type=Path, help="Input images directory (if not extracting from zip).")
    parser.add_argument("--work-dir", type=Path, default=Path("data/.dataset-import"), help="Temp extraction directory.")
    parser.add_argument("--output-db", type=Path, required=True, help="Output sqlite path.")
    parser.add_argument("--output-images-dir", type=Path, required=True, help="Output images directory path.")
    parser.add_argument(
        "--canonicalize-easa-top-level",
        action="store_true",
        help="Map top-level categories by EASA code to canonical app IDs.",
    )
    parser.add_argument(
        "--create-icon-aliases",
        action="store_true",
        help="Create <canonicalTopLevelId>.png aliases in output images.",
    )
    parser.add_argument("--report-json", type=Path, help="Optional JSON report output path.")
    return parser.parse_args()


def extract_zip(source_zip: Path, work_dir: Path) -> Path:
    if work_dir.exists():
        shutil.rmtree(work_dir)
    work_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(source_zip, "r") as archive:
        for member in archive.infolist():
            normalized_name = member.filename.replace("\\", "/")
            normalized_path = Path(normalized_name)

            if normalized_path.name == "":
                continue

            output_path = work_dir / normalized_path
            if member.is_dir() or member.filename.endswith(("/", "\\")):
                output_path.mkdir(parents=True, exist_ok=True)
                continue

            output_path.parent.mkdir(parents=True, exist_ok=True)
            with archive.open(member, "r") as source_stream, output_path.open("wb") as dest_stream:
                shutil.copyfileobj(source_stream, dest_stream)
    return work_dir


def find_first_sqlite(search_root: Path) -> Path:
    matches = sorted(search_root.rglob("*.sqlite"))
    if not matches:
        raise RuntimeError(f"No .sqlite file found under {search_root}")
    if len(matches) > 1:
        print(f"[warn] multiple sqlite files found, using first: {matches[0]}")
    return matches[0]


def find_best_images_dir(search_root: Path) -> Path:
    best_dir: Path | None = None
    best_count = -1
    for candidate in search_root.rglob("*"):
        if not candidate.is_dir():
            continue
        count = 0
        try:
            for child in candidate.iterdir():
                if child.is_file() and child.suffix.lower() in IMAGE_EXTENSIONS:
                    count += 1
        except OSError:
            continue
        if count > best_count:
            best_count = count
            best_dir = candidate
    if best_dir is None or best_count <= 0:
        raise RuntimeError(f"No images directory found under {search_root}")
    return best_dir


def table_columns(conn: sqlite3.Connection, table_name: str) -> set[str]:
    rows = conn.execute(f"PRAGMA table_info({table_name})").fetchall()
    return {row[1] for row in rows}


def validate_schema(conn: sqlite3.Connection) -> None:
    for table, required_columns in REQUIRED_TABLE_COLUMNS.items():
        existing_columns = table_columns(conn, table)
        if not existing_columns:
            raise RuntimeError(f"Missing table: {table}")
        missing_columns = sorted(required_columns - existing_columns)
        if missing_columns:
            raise RuntimeError(f"Table {table} missing required columns: {', '.join(missing_columns)}")


def normalize_top_level_ids(conn: sqlite3.Connection) -> list[dict[str, object]]:
    top_level = conn.execute(
        """
        SELECT id, code, name
        FROM categories
        WHERE parent IS NULL OR parent = 0
        """
    ).fetchall()

    remaps: list[dict[str, object]] = []
    for old_id, code, name in top_level:
        code_str = str(code) if code is not None else ""
        target_id = EASA_CANONICAL_TOP_LEVEL_ID_BY_CODE.get(code_str)
        if target_id is None or old_id == target_id:
            continue

        occupied = conn.execute("SELECT id FROM categories WHERE id = ?", (target_id,)).fetchone()
        if occupied and occupied[0] != old_id:
            raise RuntimeError(
                f"Cannot remap top-level category code {code_str} from {old_id} to {target_id}: target ID occupied."
            )

        remaps.append(
            {
                "old_id": int(old_id),
                "new_id": int(target_id),
                "code": code_str,
                "name": str(name or ""),
            }
        )

    if not remaps:
        return remaps

    conn.execute("BEGIN")
    try:
        for remap in remaps:
            old_id = remap["old_id"]
            new_id = remap["new_id"]

            conn.execute("UPDATE categories SET id = ? WHERE id = ?", (new_id, old_id))
            conn.execute("UPDATE categories SET parent = ? WHERE parent = ?", (new_id, old_id))
            conn.execute("UPDATE questions SET category = ? WHERE category = ?", (new_id, old_id))
            conn.execute("UPDATE category_iap SET category_id = ? WHERE category_id = ?", (new_id, old_id))
            conn.execute("UPDATE category_usergroup SET category_id = ? WHERE category_id = ?", (new_id, old_id))

        conn.commit()
    except Exception:
        conn.rollback()
        raise

    return remaps


def copy_resources(source_db: Path, source_images_dir: Path, output_db: Path, output_images_dir: Path) -> None:
    output_db.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source_db, output_db)

    source_resolved = source_images_dir.resolve()
    output_resolved = output_images_dir.resolve()
    if source_resolved == output_resolved:
        raise RuntimeError("output-images-dir must differ from source-images-dir")

    if output_images_dir.exists():
        shutil.rmtree(output_images_dir)
    shutil.copytree(source_images_dir, output_images_dir)


def ensure_icon_aliases(images_dir: Path, remaps: list[dict[str, object]]) -> int:
    aliases_created = 0
    for remap in remaps:
        old_id = remap["old_id"]
        new_id = remap["new_id"]
        code = remap["code"]

        target = images_dir / f"{new_id}.png"
        if target.exists():
            continue

        candidates = [
            images_dir / f"{old_id}.png",
            images_dir / f"{code}.png",
        ]
        source = next((candidate for candidate in candidates if candidate.exists()), None)
        if source is None:
            continue

        shutil.copy2(source, target)
        aliases_created += 1

    return aliases_created


def strip_guide_html(images_dir: Path) -> bool:
    guide = images_dir / "guide.html"
    if guide.exists():
        guide.unlink()
        return True
    return False


def attachment_missing_files(conn: sqlite3.Connection, images_dir: Path) -> list[str]:
    rows = conn.execute("SELECT filename FROM attachments").fetchall()
    missing: list[str] = []
    for (filename,) in rows:
        if not filename:
            continue
        if not (images_dir / filename).exists():
            missing.append(str(filename))
    return missing


def dataset_counts(conn: sqlite3.Connection) -> dict[str, int]:
    result: dict[str, int] = {}
    for table in ("questions", "categories", "attachments", "category_groups"):
        value = conn.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
        result[table] = int(value)
    return result


def main() -> None:
    args = parse_args()

    source_root: Path | None = None
    if args.source_zip:
        if not args.source_zip.exists():
            raise RuntimeError(f"source-zip not found: {args.source_zip}")
        source_root = extract_zip(args.source_zip, args.work_dir)

    source_db = args.source_db
    if source_db is None:
        if source_root is None:
            raise RuntimeError("Provide --source-db or --source-zip.")
        source_db = find_first_sqlite(source_root)
    if not source_db.exists():
        raise RuntimeError(f"source-db not found: {source_db}")

    source_images_dir = args.source_images_dir
    if source_images_dir is None:
        if source_root is None:
            raise RuntimeError("Provide --source-images-dir or --source-zip.")
        source_images_dir = find_best_images_dir(source_root)
    if not source_images_dir.exists():
        raise RuntimeError(f"source-images-dir not found: {source_images_dir}")

    copy_resources(source_db, source_images_dir, args.output_db, args.output_images_dir)

    conn = sqlite3.connect(args.output_db)
    try:
        validate_schema(conn)
        remaps: list[dict[str, object]] = []
        if args.canonicalize_easa_top_level:
            remaps = normalize_top_level_ids(conn)

        aliases_created = ensure_icon_aliases(args.output_images_dir, remaps) if args.create_icon_aliases else 0
        guide_removed = strip_guide_html(args.output_images_dir)
        missing_images = attachment_missing_files(conn, args.output_images_dir)
        counts = dataset_counts(conn)
    finally:
        conn.close()

    report = {
        "source_db": str(source_db),
        "source_images_dir": str(source_images_dir),
        "output_db": str(args.output_db),
        "output_images_dir": str(args.output_images_dir),
        "counts": counts,
        "canonicalized_top_level_count": len(remaps),
        "canonicalized_top_levels": remaps,
        "icon_aliases_created": aliases_created,
        "guide_html_removed": guide_removed,
        "missing_attachment_images_count": len(missing_images),
        "missing_attachment_images_sample": missing_images[:25],
    }

    print(json.dumps(report, indent=2))
    if args.report_json:
        args.report_json.parent.mkdir(parents=True, exist_ok=True)
        args.report_json.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
