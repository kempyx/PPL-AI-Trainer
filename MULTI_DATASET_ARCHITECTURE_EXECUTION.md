# Multi-Dataset Architecture and Implementation Plan (LLM Execution Spec)

## 1. Objective

Enable `PPLAITrainer` to support multiple question datasets (for language variants and content updates), each with its own SQLite source and related images, while keeping existing app behavior stable.

Primary outcomes:
- Runtime-selectable dataset (example: `en`, `es`, `fr`, or versioned updates like `en-v154`).
- Dataset-specific database + assets loading.
- No cross-dataset progress corruption.
- Minimal regression risk for quiz correctness, SRS scheduling, and stats.

---

## 2. Non-Negotiable Constraints

Implement within current project rules:
- iOS 17+, SwiftUI, MVVM.
- Observation with `@Observable` and `@State` (no `ObservableObject`, `@Published`, `@StateObject` for new work).
- Persistence via GRDB through `DatabaseManaging` / `DatabaseManager`.
- Dependencies created in `PPLAITrainerApp` and injected through `Dependencies`.
- Async/await for new async flows.
- Preserve current quiz/mock exam logic and DB write correctness.

---

## 3. Current Gaps (Why Change Is Needed)

Today the app is single-dataset and hardcoded:
- DB file name is fixed to `153-en.sqlite` and copied once.
- Image loading is direct `Bundle.main.path(...)` calls in multiple files.
- `DatabaseManager` is created without dataset config.
- Settings has no active dataset/language concept.
- User progress tables reference `questionId`; swapping content without strategy can orphan or mis-map progress.

---

## 4. Target Architecture (High-Level)

### 4.1 Core Concept

Treat each dataset as a package with:
- metadata (`id`, language, version, display name),
- bundled source DB resource name,
- bundled images directory name,
- optional category icon directory name.

Example dataset IDs:
- `easa.en.v153`
- `easa.en.v154`
- `easa.es.v153`

### 4.2 Isolation Strategy

Use one local database file per dataset (recommended v1):
- local DB path includes dataset ID,
- each dataset gets its own migrated user tables,
- switching datasets swaps the active DB instance,
- no shared user table between unrelated datasets.

This avoids accidental data mixing and removes the need to add `datasetId` columns across all user tables in v1.

### 4.3 Asset Strategy

Replace direct `Bundle.main` image lookups with an injected asset provider:
- resolves question/explanation images for active dataset,
- resolves category icon assets for active dataset,
- provides base64 data URLs for AI multimodal context.

### 4.4 Runtime Switching

Add an app bootstrap coordinator that can rebuild dependencies when dataset changes:
- user picks dataset in Settings,
- app updates active dataset setting,
- app reinitializes `DatabaseManager` and dependent services,
- UI continues with new active dependencies.

---

## 5. Data Contracts

## 5.1 Dataset Manifest (Bundle)

Add a bundled manifest JSON (example path):
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
      "imagesDirectory": "QuestionImages-en",
      "categoryIconsDirectory": "CategoryIcons-en"
    }
  ]
}
```

## 5.2 Required SQLite Tables for Every Dataset

Each dataset SQLite must include at least:
- `questions`
- `categories`
- `attachments`
- `category_groups`

Required columns must remain compatible with current models:
- `questions`: `id`, `category`, `code`, `text`, `correct`, `incorrect0`, `incorrect1`, `incorrect2`, `explanation`, `reference`, `attachments`, `mockonly`
- `categories`: `id`, `parent`, `quantityinmock`, `code`, `name`, `categorygroup`, `sortorder`, `locked`
- `attachments`: `id`, `name`, `filename`, `explanation`
- `category_groups`: `id`, `name`

If schema differs, add an explicit adapter layer. Do not silently coerce.

## 5.3 Question Identity Contract

For future progress carryover between versions, require stable `questions.code` semantics across revisions of the same family/language.

---

## 6. New Types and Services

Add these types/services:

1. `DatasetDescriptor` (model)
- fields from manifest per dataset.

2. `DatasetManifest` (model)
- `defaultDatasetId`
- `datasets`

3. `DatasetCatalogManaging` protocol + `BundledDatasetCatalog`
- load manifest from bundle,
- return all datasets,
- return default dataset,
- lookup by ID.

4. `ActiveDatasetStore`
- backed by `SettingsManager`,
- get/set current dataset ID.

5. `QuestionAssetProviding` protocol + `BundleQuestionAssetProvider`
- `uiImage(filename:)`
- `imageDataURL(filename:)`
- `categoryIcon(categoryId:)`
- all resolved against active dataset directories.

6. `AppBootstrapper` (`@Observable`)
- owns `deps: Dependencies?`, `initError: String?`,
- `load()` and `switchDataset(to:)`,
- rebuilds dependencies on switch.

7. `DatabaseManager.Configuration`
- `dataset: DatasetDescriptor`,
- local DB filename/path strategy.

---

## 7. File-by-File Implementation Plan

Execute phases in order. Keep each phase compile-ready.

## Phase 1: Dataset Foundation

Create:
- `PPLAITrainer/Models/DatasetDescriptor.swift`
- `PPLAITrainer/Services/DatasetCatalog.swift`

Update:
- `PPLAITrainer/Services/SettingsManager.swift`

Add settings key:
- `activeDatasetId: String?`

Definition of done:
- dataset list can be loaded from manifest.
- active dataset ID can be persisted in settings.

## Phase 2: Database Configuration Refactor

Update:
- `PPLAITrainer/Services/DatabaseManager.swift`

Add:
- `struct Configuration` with dataset descriptor.
- init `init(configuration:) throws`.
- local DB path strategy: `Application Support/PPLAITrainer/Datasets/<datasetId>.sqlite`.
- copy from bundle resource named by descriptor when local file does not exist.

Keep:
- all existing migrations unchanged.
- all protocol methods unchanged.

Definition of done:
- app can instantiate DB manager for any manifest dataset.
- each dataset maps to distinct local DB file.

## Phase 3: Asset Provider Injection

Create:
- `PPLAITrainer/Services/QuestionAssetProvider.swift`

Update call sites to remove direct `Bundle.main` lookups:
- `PPLAITrainer/Views/Quiz/QuestionView.swift`
- `PPLAITrainer/Views/Quiz/ResultView.swift`
- `PPLAITrainer/ViewModels/QuizViewModel.swift`
- `PPLAITrainer/Views/Study/CategoryListView.swift`

Definition of done:
- all question/explanation/category icon image reads use `QuestionAssetProviding`.
- AI image context generation uses provider data URL method.

## Phase 4: Dependency Graph and App Bootstrap

Create:
- `PPLAITrainer/Services/AppBootstrapper.swift`

Update:
- `PPLAITrainer/Services/Dependencies.swift`
- `PPLAITrainer/PPLAITrainerApp.swift`

Changes:
- add dataset catalog + active dataset + asset provider into `Dependencies`.
- app startup uses bootstrapper to build deps from current dataset.
- bootstrapper exposes `switchDataset(to:)` that reconstructs deps.

Definition of done:
- app starts with configured default/selected dataset.
- changing dataset can rebuild active dependencies without app reinstall.

## Phase 5: Settings UI for Dataset Selection

Update:
- `PPLAITrainer/ViewModels/SettingsViewModel.swift`
- `PPLAITrainer/Views/Settings/SettingsView.swift`

Add:
- list of available datasets with current selection.
- confirmation prompt before switching.
- clear user messaging: progress is stored per dataset in v1.

Definition of done:
- user can switch dataset from Settings.
- app reloads with new dataset and corresponding assets.

## Phase 6 (Optional v2): Progress Carryover Between Revisions

Only for related datasets (same `familyId` and same language):
- migrate user records by joining old/new questions via stable `questions.code`.
- supported tables for remap: `answer_records`, `srs_cards`, `mnemonics`, `bookmarks`, `notes`, `ai_response_cache`.
- if code collision/missing mapping occurs, skip those rows and log summary.

Definition of done:
- carryover is explicit, opt-in, and loss-reporting is visible in logs.

---

## 8. Required Behavior Rules

Rules the implementing LLM must follow:
- Never hardcode `153-en` outside manifest/default bootstrap fallback.
- Never load question assets directly from `Bundle.main` in views/viewmodels.
- Never merge progress from unrelated dataset families.
- Never delete another dataset local DB unless explicitly requested by user action.
- Keep `DatabaseManaging` method signatures backward-compatible during refactor.

---

## 9. Acceptance Criteria

All criteria must pass:

1. Fresh install:
- default dataset loads questions and images correctly.

2. Dataset switch:
- switching to another dataset changes question corpus and assets.
- no crash during app reload.

3. Isolation:
- answers/SRS/progress recorded in dataset A do not appear in dataset B.

4. Existing features:
- quiz flow, mock exam flow, SRS stats, bookmarks, notes, AI explanation cache remain functional.

5. Fallback behavior:
- if a dataset image is missing, UI degrades gracefully (no crash).

6. Manifest validation:
- invalid manifest or missing DB resource yields clear init error.

---

## 10. Verification Checklist for Implementing LLM

Run in repo root:

```bash
./scripts/check.sh
```

Manual smoke checks:
- open quiz question with attachments and verify image load.
- open result view explanation attachments and verify image load.
- category list icons still render or fallback icon appears.
- switch dataset in settings and verify content changes.
- answer a few questions in both datasets and verify isolation.

---

## 11. Rollout Strategy

Recommended rollout:
- ship Phase 1 through Phase 5 first (safe isolation, no carryover complexity).
- collect telemetry and stability data.
- then implement optional Phase 6 carryover by `questions.code`.

---

## 12. Suggested Commit Plan (for implementing LLM)

1. `feat(dataset): add manifest models and dataset catalog`
2. `feat(db): parameterize DatabaseManager by dataset configuration`
3. `feat(assets): add QuestionAssetProvider and replace bundle image lookups`
4. `feat(app): add bootstrapper and dependency reload for dataset switching`
5. `feat(settings): add dataset selector UI and switching flow`
6. `feat(migration): optional question-code based progress carryover`

---

## 13. Explicitly Out of Scope for v1

- Downloading datasets from network/CDN.
- Delta patching large dataset files.
- Background sync of question packs.
- Multi-tenant shared progress across languages by translation mapping.

