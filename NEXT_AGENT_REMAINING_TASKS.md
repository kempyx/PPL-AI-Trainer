# Next Agent Handoff - Remaining Tasks

Branch baseline: `codex/subagent-ux-masterplan-execution`
Baseline commit: `b2743c3` (WS6 complete)

## Completed in this branch
- Contextual selected-text explain + pre-submit hints + quiz interaction telemetry.
- Habit-loop improvements, mock exam remediation, trust copy guardrails.
- Experiment variants + KPI panel + KPI markdown export.
- WS6 cognitive-load scaffolding in quiz flow:
  - Focus Steps for dense aviation questions.
  - Reference-figure guardrails (open-before-submit cues + zoom guidance).
  - Result-view debrief chunking with expandable official explanation.

## Remaining Tasks (for next sub-agent)

### P0 - WS7 Micro-Interaction and Feedback Polish
Task ID: `WS7-T1`
- Goal: Tighten correctness feedback and pacing without changing scoring logic.
- Scope:
  - Add subtle transition choreography for `Submit -> Result` and `Next Question`.
  - Ensure feedback timing is consistent for correct/incorrect states.
  - Keep behavior native iOS/HIG and avoid flashy motion.
- Likely files:
  - `PPLAITrainer/Views/Quiz/QuizSessionView.swift`
  - `PPLAITrainer/Views/Quiz/ResultView.swift`
  - `PPLAITrainer/Views/Common/AnimationModifiers.swift`
- Done criteria:
  - No regression in answer submission, progression, or session completion.
  - Motion is noticeable but brief (<= 350ms for most transitions).
  - `./scripts/check.sh` passes.

Task ID: `WS7-T2`
- Goal: Close haptic feedback gaps in quiz flows.
- Scope:
  - Audit current haptic triggers and add missing events for key moments:
    - Hint reveal success/failure.
    - Contextual explain request success/failure.
    - Result debrief reveal/open.
  - Respect `settingsManager.hapticFeedbackEnabled` and do not duplicate haptics.
- Likely files:
  - `PPLAITrainer/ViewModels/QuizViewModel.swift`
  - `PPLAITrainer/Services/HapticService.swift`
  - `PPLAITrainer/Services/SettingsManager.swift` (only if new toggle key needed)
- Done criteria:
  - Haptics fire once per event and are disabled when toggle is off.
  - No new side effects in mock exam or flashcards.
  - `./scripts/check.sh` passes.

### P0 - WS8 Instrument WS6 for KPI/Experiment Readout
Task ID: `WS8-T1`
- Goal: Measure whether WS6 scaffolding is actually used.
- Scope:
  - Add interaction events for:
    - Focus steps displayed.
    - Reference figure opened.
    - Official explanation expanded/collapsed.
    - Quick debrief shown.
  - Keep event names stable and metadata concise.
- Likely files:
  - `PPLAITrainer/Views/Quiz/QuestionView.swift`
  - `PPLAITrainer/Views/Quiz/ResultView.swift`
  - `PPLAITrainer/ViewModels/QuizViewModel.swift`
  - `PPLAITrainer/Services/DatabaseManager.swift` (only if aggregation needs extension)
  - `PPLAITrainer/Views/Settings/SettingsView.swift` (if exposing new counters)
- Done criteria:
  - New events appear in existing interaction-event aggregation.
  - No schema-breaking migration required unless justified.
  - `./scripts/check.sh` passes.

### P1 - WS9 Extend Cognitive-Load Safeguards to Mock Exam
Task ID: `WS9-T1`
- Goal: Align quiz and mock-exam comprehension support for chart/weather/performance items.
- Scope:
  - Port lightweight, non-intrusive comprehension cues into mock exam question rendering.
  - Do not reduce timer clarity or exam pacing.
- Likely files:
  - `PPLAITrainer/Views/MockExam/MockExamSessionView.swift`
  - Shared view(s) reused from quiz where possible.
- Done criteria:
  - No regression in mock exam scoring/submission/timer behavior.
  - UI remains legible under time pressure.
  - `./scripts/check.sh` passes.

### P1 - WS10 Legacy Parity + Trust QA Pass
Task ID: `WS10-T1`
- Goal: Verify critical old behaviors remain credible after redesign.
- Scope:
  - Validate and document parity for:
    - Text selection highlight in question/result text.
    - Contextual explain action and AI explanation flow.
    - Hint mechanics and engagement loops.
  - If `/tmp/from_old_code` is available, compare behavior directly; if not, document blocker.
- Likely files:
  - `PPLAITrainer/Views/Quiz/QuestionView.swift`
  - `PPLAITrainer/Views/Quiz/QuizSessionView.swift`
  - `PPLAITrainer/Views/Quiz/ResultView.swift`
  - `PPLAITrainer/ViewModels/QuizViewModel.swift`
- Done criteria:
  - QA checklist markdown added with pass/fail + evidence screenshots.
  - Any trust-risk issue is flagged before merge.
  - `./scripts/check.sh` passes.

## Constraints for next agent
- Keep iOS 17+ / SwiftUI / MVVM (`@Observable`, `@State` VM refs) pattern compliance.
- Preserve quiz correctness logic, SRS writes, and DB safety.
- Prefer incremental PR-sized commits; avoid broad refactors.
- Do not edit bundled question content.

## Recommended execution order
1. `WS7-T1` and `WS7-T2` (parallel possible if touching separate files).
2. `WS8-T1` (depends on final interaction points from WS7).
3. `WS9-T1` (can run parallel to WS8 if shared components are stable).
4. `WS10-T1` final QA/trust gate before merge.
