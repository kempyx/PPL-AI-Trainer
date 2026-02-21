# PPLAITrainer

iOS app for EASA PPL theory exam prep, with 2,681 questions, spaced repetition, mock exams, progress tracking, and AI explanations.

## Stack
- Swift + SwiftUI (iOS 17+)
- MVVM with Observation (`@Observable`)
- SQLite via GRDB
- Dependency injection via `Dependencies` environment

## Project Layout
- App code: `/Users/kemp.calalo/Documents/ios/PPLAITrainer/PPLAITrainer`
- Xcode project: `/Users/kemp.calalo/Documents/ios/PPLAITrainer/PPLAITrainer.xcodeproj`
- Core context and conventions: `/Users/kemp.calalo/Documents/ios/PPLAITrainer/CLAUDE.md`
- Agent execution rules: `/Users/kemp.calalo/Documents/ios/PPLAITrainer/AGENTS.md`

## Quickstart
1. Open `/Users/kemp.calalo/Documents/ios/PPLAITrainer/PPLAITrainer.xcodeproj` in Xcode.
2. Select scheme `PPLAITrainer`.
3. Run on an iOS 17+ simulator/device.

## CLI Verification
Run:

```bash
cd /Users/kemp.calalo/Documents/ios/PPLAITrainer
./scripts/check.sh
```

This script builds with repo-local caches (`.build/`) to improve reproducibility for local automation.

## Codex Cloud Notes
- `./scripts/check.sh` auto-detects whether Xcode is available.
- On macOS + Xcode: it runs full `xcodebuild` validation.
- On Codex Cloud/Linux (no Xcode): it automatically runs `./scripts/check-cloud.sh` for cloud-safe validation.
- For iOS build confidence, run the full check on a macOS environment before release.
- CI is configured at `/Users/kemp.calalo/Documents/ios/PPLAITrainer/.github/workflows/ios-build.yml` to run full macOS builds on `push`/`pull_request`.

## Notes
- `PPLAITrainer/Resources/153-en.sqlite` is bundled read-only reference data.
- User progress/history data is stored in app-managed tables created by migrations.
- API keys are stored in Keychain, settings in `UserDefaults` (`SettingsManager`).
