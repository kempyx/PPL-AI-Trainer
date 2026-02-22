# AGENTS.md

## Goal
Ship safe, incremental changes to `PPLAITrainer` with reproducible local verification.

## Project Rules
- Platform: iOS 17+, SwiftUI, MVVM.
- Observation: use `@Observable` + `@State` view model references (not `ObservableObject`, not `@Published`, not `@StateObject`).
- Persistence: SQLite via GRDB (`DatabaseManaging` protocol, `DatabaseManager` implementation).
- DI: create services in `PPLAITrainerApp` and pass through `Dependencies` environment.
- Concurrency: async/await only, no callback-style completion handlers for new code.
- Navigation: `NavigationStack` + `NavigationLink`.
- Keep file names aligned with primary type.

## Data Constraints
- Bundled DB `PPLAITrainer/Resources/153-en.sqlite` is read-only source data.
- User data must go through migrations/tables managed by `DatabaseManager`.
- Do not edit bundled question content directly in app code.

## Change Workflow
1. Read `CLAUDE.md` for architecture and domain context.
2. Make the smallest viable change that resolves the task.
3. Run `./scripts/check.sh`.
4. If `check.sh` falls back to cloud-safe checks (no Xcode), report that full iOS compilation still requires a macOS runner or local Mac.
5. If build/check cannot run in sandbox, report the exact blocker and what was still validated.

## Verification Command
- Primary: `./scripts/check.sh`
- Cloud-safe fallback: `./scripts/check-cloud.sh` (invoked automatically by `check.sh` when Xcode is unavailable)

## Priorities
- Preserve quiz/mock-exam correctness and answer-stat logic.
- Avoid regressions in SRS scheduling and database writes.
- Keep UI behavior consistent with current flows unless task explicitly changes UX.
