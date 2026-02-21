#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Running cloud-safe checks (no Xcode required)..."

if command -v rg >/dev/null 2>&1; then
  if rg -n "^(<<<<<<<|=======|>>>>>>>)" "$ROOT_DIR/PPLAITrainer" >/dev/null; then
    echo "Merge conflict markers detected."
    exit 1
  fi
else
  echo "ripgrep not available; skipping conflict-marker check."
fi

if [[ ! -f "$ROOT_DIR/PPLAITrainer.xcodeproj/project.pbxproj" ]]; then
  echo "Missing Xcode project file."
  exit 1
fi

SWIFT_FILE_COUNT="$(find "$ROOT_DIR/PPLAITrainer" -name '*.swift' | wc -l | tr -d ' ')"
if [[ "${SWIFT_FILE_COUNT:-0}" -eq 0 ]]; then
  echo "No Swift source files found."
  exit 1
fi

echo "Cloud-safe checks passed."
