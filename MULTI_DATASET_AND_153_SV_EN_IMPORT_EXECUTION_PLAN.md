# Multi-Dataset + 153-sv-en Import Execution Plan (LLM Implementation Spec)

## 1) Objective

Implement multi-dataset support in `PPLAITrainer` and import `153-sv-en` as a first-class dataset, while preserving app correctness and allowing users to keep isolated progress per dataset.

Primary goals:
- Runtime dataset switching (`153-en`, `153-sv-en`, future datasets).
- Isolated progress per dataset/profile (switching dataset starts from that dataset's own progress state).
- Locked/premium content supported in data model, hidden by default, optionally visible via settings flag.
- A repeatable pre-processing pipeline for incoming SQLite bundles before they are added to iOS resources.

---

## 2) Locked Product Decisions (already agreed)

1. Dataset switching should use isolated progress.
- User progress is tied to the selected dataset profile.
- Switching from dataset A to B should feel like a fresh profile unless B has prior progress.

2. Locked/premium content behavior.
- Locked categories remain hidden by default.
- Add a settings flag `showPremiumContent` to reveal locked content for internal/testing mode.
- Future IAP unlock can flip this behavior; do not implement IAP now.

3. Multi-dataset shipping model.
- `datasets.json` should list only real installed datasets (no placeholders).

4. Safety on switch.
- Dataset switch triggers dependency rebuild and safe root reset.

5. v1 carryover.
- No cross-dataset carryover in v1.
- Keep extension points/logging only.

---

## 3) Non-Negotiable Engineering Constraints

- iOS 17+, SwiftUI, MVVM.
- Use Observation (`@Observable`, `@State` view model refs), no new `ObservableObject`/`@Published`/`@StateObject`.
- Persistence via GRDB behind `DatabaseManaging` / `DatabaseManager`.
- Dependencies created at app level and injected via `Dependencies` environment.
- Async/await for new async flows.
- Preserve quiz correctness, mock-exam correctness, SRS correctness, and write integrity.
- Keep file names aligned with primary type.

---

## 4) Target Architecture

## 4.1 Dataset and Profile Model

Use two concepts:

- `Dataset`: content package (SQLite + images + metadata).
- `Profile`: progress container bound to a dataset.

### v1 simplification
Use one automatic profile per dataset:
- `profileId = datasetId`
- Switching dataset => switching effective profile.
- No custom profile management UI yet.

This gives profile isolation now with minimal UX overhead.

## 4.2 Storage Layout

- Bundled source DBs remain in app resources.
- Local mutable DB path:
  - `Application Support/PPLAITrainer/Datasets/<datasetId>/<profileId>.sqlite`
- Migrations run per local DB file.

## 4.3 Dataset Manifest

Create and load bundled manifest:
- `PPLAITrainer/Resources/Datasets/datasets.json`

Suggested shape:

```json
{
  "defaultDatasetId": "easa.en.v153",
  "datasets": [
    {
      "id": "easa.en.v153",
      "familyId": "easa",
      "languageCode": "en",
      "version": "153",
      "displayName": "English (v153)",
      "databaseResourceName": "153-en",
      "databaseExtension": "sqlite",
      "imagesDirectory": "QuestionImages",
      "categoryIconsDirectory": "QuestionImages",
      "examMapping": {
        "technicalLegal": ["21", "22", "81", "10"],
        "humanEnvironment": ["50", "40", "91"],
        "planningNavigation": ["61", "62", "31", "32", "33", "70"]
      }
    },
    {
      "id": "easa.sv-en.v153",
      "familyId": "easa",
      "languageCode": "sv-en",
      "version": "153",
      "displayName": "SV+EN (v153)",
      "databaseResourceName": "153-sv-en",
      "databaseExtension": "sqlite",
      "imagesDirectory": "QuestionImages-sv-en",
      "categoryIconsDirectory": "QuestionImages-sv-en",
      "examMapping": {
        "technicalLegal": ["21", "22", "81", "10"],
        "humanEnvironment": ["50", "40", "91"],
        "planningNavigation": ["61", "62", "31", "32", "33", "70"]
      }
    }
  ]
}
```

Notes:
- `examMapping` is by `categories.code` (not ID), so datasets can use different category IDs safely.
- Keep `datasetId` constrained to `[a-z0-9._-]+`.

## 4.4 Services and Types

Add/update:

1. `DatasetDescriptor`
- Includes manifest fields and optional exam mapping.

2. `DatasetManifest`
- `defaultDatasetId` and `[DatasetDescriptor]`.

3. `DatasetCatalogManaging` + `BundledDatasetCatalog`
- Load/validate manifest.
- Resolve default and lookup by ID.

4. `ActiveDatasetStore`
- Persist active dataset ID in `SettingsManager`.

5. `ActiveProfileStore`
- Persist active profile ID per dataset (v1 can default `profileId = datasetId`).

6. `QuestionAssetProviding` + `BundleQuestionAssetProvider`
- Resolve all question and category images from active dataset dirs.

7. `AppBootstrapper` (`@Observable`)
- Owns `deps`, `initError`.
- `load()` and `switchDataset(to:)`.
- Rebuilds full dependency graph.

8. `DatabaseManager.Configuration`
- Requires `dataset` + `profileId`.
- Computes local DB path.

## 4.5 Replace Hardcoded Category IDs

Current logic uses old fixed IDs (for example in `MockExamEngine` and `GamificationService`), which will break with `153-sv-en`.

Refactor to dataset-driven lookups:
- Resolve top-level categories by `categories.code` using manifest `examMapping`.
- Build leg parent IDs at runtime from active dataset.
- Achievements/mastery checks should also resolve by category code-to-ID at runtime, not constants.

---

## 5) Implementation Phases (LLM Work Plan)

## Phase 1: Dataset Foundation

Create:
- `PPLAITrainer/Models/DatasetDescriptor.swift`
- `PPLAITrainer/Services/DatasetCatalog.swift`

Update:
- `PPLAITrainer/Services/SettingsManager.swift`
  - `activeDatasetId: String?`
  - `activeProfileId: String?` (or map by dataset)

Definition of done:
- Manifest loads.
- Active dataset/profile persist.

## Phase 2: Database Configuration + Profile Isolation

Update:
- `PPLAITrainer/Services/DatabaseManager.swift`

Add:
- `Configuration(dataset: DatasetDescriptor, profileId: String)`.
- local path strategy per dataset/profile.
- copy bundled source DB on first use of that dataset/profile.

Definition of done:
- Separate files for `153-en` and `153-sv-en` progress.
- Existing migrations still run unchanged per DB file.

## Phase 3: Asset Provider Injection

Create:
- `PPLAITrainer/Services/QuestionAssetProvider.swift`

Replace direct bundle image reads in:
- `PPLAITrainer/Views/Quiz/QuestionView.swift`
- `PPLAITrainer/Views/Quiz/ResultView.swift`
- `PPLAITrainer/ViewModels/QuizViewModel.swift`
- `PPLAITrainer/Views/Study/CategoryListView.swift`

Definition of done:
- No direct `Bundle.main.path(...)` image logic in view/viewmodel call sites.

## Phase 4: App Bootstrapper and Dataset Switching

Create:
- `PPLAITrainer/Services/AppBootstrapper.swift`

Update:
- `PPLAITrainer/Services/Dependencies.swift`
- `PPLAITrainer/PPLAITrainerApp.swift`

Definition of done:
- App starts from active/default dataset.
- `switchDataset` rebuilds deps and resets to app root safely.

## Phase 5: Settings UI for Dataset and Profile Binding

Update:
- `PPLAITrainer/ViewModels/SettingsViewModel.swift`
- `PPLAITrainer/Views/Settings/SettingsView.swift`

Add:
- dataset selector
- confirmation sheet before switching
- explanatory text: progress is dataset-profile isolated

Definition of done:
- User can switch dataset.
- Returning to a dataset resumes that dataset profile state.

## Phase 6: Dataset-Driven Leg Mapping + Mastery

Update:
- `PPLAITrainer/Services/MockExamEngine.swift`
- `PPLAITrainer/Services/SmartSessionEngine.swift`
- `PPLAITrainer/Services/GamificationService.swift`

Refactor:
- No hardcoded top-level category IDs.
- Resolve runtime parent IDs using dataset `examMapping` and `categories.code`.

Definition of done:
- Legs/exams/workflows work correctly for both `153-en` and `153-sv-en`.

## Phase 7: Locked Content Visibility Rules

Update:
- Study category loading paths to enforce:
  - hidden when `showPremiumContent == false`
  - visible when `true`

Definition of done:
- Locked categories are not shown by default.
- Toggle reveals them immediately without restart.

## Phase 8: Defensive Validation and Init Error UX

On startup fail with clear init error if:
- manifest invalid
- default dataset missing
- dataset DB resource missing

Definition of done:
- User sees deterministic error state, not crash.

---

## 6) Pre-Processing Pipeline for Incoming Datasets

Build reusable tooling in repo:

- `scripts/datasets/ingest.py`
- `scripts/datasets/profiles/<source-profile>.yaml`
- `scripts/datasets/README.md`

CLI interface:

```bash
python3 scripts/datasets/ingest.py inspect --input <zip-or-sqlite>
python3 scripts/datasets/ingest.py normalize --input <zip-or-sqlite> --profile <profile>
python3 scripts/datasets/ingest.py validate --workdir <normalized-dir> --strict
python3 scripts/datasets/ingest.py package --workdir <normalized-dir> --dataset-id <id>
```

Pipeline stages:

1. `inspect`
- unzip input (if zip)
- detect sqlite file
- print table list, required columns, row counts, top-level/subcategory counts
- detect orphan refs and missing files

2. `normalize`
- apply profile-specific SQL/transformations
- normalize text fixes
- generate deterministic report JSON

3. `validate`
- enforce hard rules (see Section 8)

4. `package`
- output:
  - normalized sqlite
  - images folder
  - manifest snippet
  - import report

---

## 7) 153-sv-en Specific Pre-Processing Plan

Input:
- ZIP: `data/153-sv-en.zip`

Observed source characteristics:
- 4349 questions, 133 categories, 331 attachments.
- Same core schema as current DB, plus `name_sv` on `categories` and `category_groups`.
- 7 locked top-level categories present.
- 10 rows with `text` prefixed `Untranslated:`.
- 12 questions with orphan `category` IDs (`504, 506, 507, 521, 551`).
- 973 blank `questions.code` values.

## 7.1 Source Profile

Create profile file:
- `scripts/datasets/profiles/153-sv-en.yaml`

Profile fields:
- dataset metadata (`id`, `displayName`, resource names)
- leg mapping by category `code`
- normalization rules

## 7.2 Normalization Rules (v1)

1. Text cleanup
- remove leading `Untranslated:` from `questions.text` and answer/explanation fields when present.

2. Orphan category remediation
- Do not drop questions silently.
- Insert synthetic locked category container for orphan references:
  - add top-level category `Imported Legacy` (locked=1, high sortorder)
  - create missing orphan category IDs as subcategories under this top-level
  - name synthetic categories using dominant `questions.code` label or fallback `Imported category <id>`
- This preserves all questions and keeps unmapped content hidden by default.

3. Blank code handling
- Fill blank `questions.code` with deterministic fallback:
  - `AUTO:<category>:<id>`
- Mark report flag `codeSemanticsReliable=false` to disable future carryover assumptions.

4. Locked flags
- Keep source `locked` values unchanged.

5. Attachment integrity
- ensure all `attachments.filename` exist in extracted image folder.

6. DB vacuum/optimize
- run `VACUUM` and `ANALYZE` after transforms.

## 7.3 Output Artifacts

Produce under `tmp/ingest/easa.sv-en.v153/`:
- `153-sv-en.normalized.sqlite`
- `QuestionImages-sv-en/` (copied images)
- `dataset-report.json`
- `datasets.snippet.json`

Then copy approved artifacts into:
- `PPLAITrainer/Resources/153-sv-en.sqlite`
- `PPLAITrainer/Resources/QuestionImages-sv-en/`
- update `PPLAITrainer/Resources/Datasets/datasets.json`

---

## 8) Validation Rules (must pass)

Hard fail rules:
- required tables missing: `questions`, `categories`, `attachments`, `category_groups`
- required columns missing from those tables
- any question with blank text/correct/incorrect options
- any orphan `questions.category` after normalization
- any orphan attachment IDs referenced by questions
- any attachment filename missing in image folder
- manifest references missing DB/images resources

Soft warnings (allowed with report):
- high ratio of auto-generated codes
- unusually high locked-content ratio
- unusually high null explanation/reference ratio

---

## 9) Test and Verification Plan

Run:

```bash
./scripts/check.sh
```

Manual smoke checks:
- Fresh install: default dataset loads.
- Switch dataset in settings: app root resets cleanly.
- Progress isolation: answer a few questions in A and B; verify separation.
- Locked content hidden by default in Study.
- Toggle `Show Premium Content` and verify locked content appears.
- Mock exam generation works in both datasets (no hardcoded ID failures).
- Attachment rendering works for sample question and explanation images.

---

## 10) Rollout Plan

1. Ship app-side multi-dataset architecture first with existing `153-en` still active.
2. Integrate ingest script and pre-process `153-sv-en`.
3. Add `153-sv-en` to manifest and enable dataset switch in internal builds.
4. Run QA on both datasets.
5. Promote `153-sv-en` as default only after exam-flow and stats parity checks.

---

## 11) Suggested Commit Sequence

1. `feat(dataset): add manifest models and dataset/profile stores`
2. `feat(db): parameterize DatabaseManager by dataset/profile configuration`
3. `feat(assets): add dataset-aware QuestionAssetProvider`
4. `feat(app): add AppBootstrapper and safe dataset switch reset`
5. `feat(settings): add dataset selector and profile-isolation messaging`
6. `refactor(exam): remove hardcoded category IDs via dataset exam mapping`
7. `feat(study): enforce locked-category visibility by showPremiumContent flag`
8. `chore(ingest): add dataset inspect/normalize/validate/package scripts`
9. `data(dataset): import normalized 153-sv-en resources and manifest entry`

---

## 12) Explicit Out of Scope for This v1

- Real IAP transaction + entitlement logic.
- Downloading datasets from network/CDN.
- Cross-dataset carryover migration.
- Multiple user-managed profiles per same dataset (beyond auto profile per dataset).

