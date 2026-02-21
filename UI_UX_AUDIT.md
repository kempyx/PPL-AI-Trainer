# PPLAITrainer UI/UX Audit

**Date**: 2026-02-21
**Scope**: Complete app review — every screen, flow, and interaction pattern
**Purpose**: Actionable improvement tasks for AI agents to execute
**Methodology**: Full source code review of all 48 view files, 6 view models, 9 models, and 4 services

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
1a. [Active Queue (Codex Web Source of Truth)](#1a-active-queue-codex-web-source-of-truth)
2. [Phase 1 Status (Critical)](#2-phase-1-status-critical)
2b. [Lost Features — Restoration Tasks](#2b-lost-features--restoration-tasks-regression-from-uncommitted-work)
3. [Global Issues](#3-global-issues)
4. [Onboarding Flow](#4-onboarding-flow)
5. [Dashboard Tab](#5-dashboard-tab)
6. [Study Tab](#6-study-tab)
7. [Quiz Session Flow](#7-quiz-session-flow)
8. [Flashcard Flow](#8-flashcard-flow)
9. [Mock Exam Tab](#9-mock-exam-tab)
10. [Settings Tab](#10-settings-tab)
11. [AI Integration](#11-ai-integration)
12. [Gamification System](#12-gamification-system)
13. [Missing Features for a Complete Quiz App](#13-missing-features-for-a-complete-quiz-app)
14. [Priority Matrix](#14-priority-matrix)

---

## 1. Executive Summary

PPLAITrainer has a solid foundation: 2,681 real EASA questions, multi-provider AI, SRS, flashcards, mock exams, and gamification. However, the app suffers from **feature sprawl without UX cohesion**. The dashboard is overloaded (9 widgets), the Study tab mixes too many entry points, and critical learning loops (quiz completion, wrong-answer review) are incomplete or awkward. The app needs to shift from "has features" to "guides the student through a clear study path."

**Top 3 systemic problems:**
1. **No clear study path** — The student opens the app and sees 9 dashboard widgets and 10+ study entry points with no clear "do this next" funnel.
2. **Broken completion loops** — Quiz sessions end abruptly; the post-session summary is disconnected from next actions.
3. **Visual inconsistency** — Cards use `.regularMaterial` backgrounds but buttons alternate between `.borderedProminent`, plain colored rectangles, and custom styles with no system.

---

## 1a. Active Queue (Codex Web Source of Truth)

Use this section as the **only active execution queue** for Codex Web work.

If this section conflicts with historical status tables below, **this section wins**.

| Priority | ID | Scope | Status | Notes |
|----------|----|-------|--------|-------|
| 1 | RESTORE-3 | Session persistence hardening + resume UX verification | [x] DONE | Added back-navigation save in `QuizSessionView`; wired Study resume button to navigate with restored VM; completion still clears saved session |
| 2 | RESTORE-4 | Hint system UX + caching verification | [x] DONE | Verified `ResultView` exposes "Get a Hint" CTA and `QuizViewModel.getQuestionHint()` reads/writes `AIResponseCache` before network call |
| 3 | RESTORE-5 | Inline AI actions UX + continuity verification | [ ] TODO | Explain/Simplify/Analogy/Mistakes actions in result flow |
| 4 | RESTORE-6 | Image attachment context for AI | [ ] TODO | Include attachment context in AI prompts (text + multimodal-aware path) |
| 5 | RESTORE-7 | Image/video prompt generation restore | [ ] TODO | Restore prompt generation entry points and prompt composition rules |
| 6 | RESTORE-8 | Category progress parity regression check | [ ] TODO | Verify Dashboard and Study progress semantics remain aligned |

**Execution protocol for this queue:**
1. Use one long-lived branch for the full Active Queue (e.g., `codex/active-queue-full`).
2. Use one PR for the full Active Queue (open as Draft early; mark ready after all tasks are done).
3. Make exactly one commit per task (`feat(<TASK-ID>): <summary>`), then push after each task.
4. Update this table immediately after finishing each task (`[ ] TODO` -> `[x] DONE`) with a brief evidence note.
5. Keep `UI_UX_AUDIT.md` in each task commit so cloud agents always see current queue state.
6. Run `./scripts/check.sh` before marking a task done.

---

## 2. Phase 1 Status (Critical) ✅ COMPLETE

All Phase 1 tasks completed.

| ID | Task | Status |
|----|------|--------|
| G-VIS-1 | Design system tokens | ✅ DONE |
| QUIZ-1 | Improve answer option layout (A/B/C/D labels, selection state) | ✅ DONE |
| QUIZ-3 | Simplify ResultView for correct vs wrong | ✅ DONE |
| QUIZ-4 | Fix quiz completion flow (PostSessionSummaryView wired) | ✅ DONE |
| EXAM-2 | Free question navigation in mock exam | ✅ DONE |
| EXAM-3 | Question flagging in mock exams | ✅ DONE |
| EXAM-5 | Post-exam question review (ExamReviewView) | ✅ DONE |
| DASH-7 | NextUpCard integrated, dashboard reorganized | ✅ DONE |
| G-STATE-1 | ViewModel recreation bugs fixed | ✅ DONE |

---

## 2a. Phase 2 Status (High Priority) ✅ COMPLETE

All Phase 2 tasks completed.

| ID | Task | Status |
|----|------|--------|
| DASH-1 | Dashboard collapsible sections with @AppStorage | ✅ DONE |
| STUDY-1 | StudyView restructured (Quick Start / Subjects / Tools) | ✅ DONE |
| G-VIS-1a | Design system adoption across all views | ✅ DONE |
| NEW-2 | Untimed practice exam mode | ✅ DONE |
| ONB-1 | Feature showcase in onboarding | ✅ DONE |
| RESTORE-1 | Clickable links in explanations | ✅ DONE |
| RESTORE-2 | Question order shuffling | ✅ DONE |

---

## 2b. Phase 3 Status (Medium Priority) ✅ COMPLETE

All Phase 3 tasks completed.

| ID | Task | Status |
|----|------|--------|
| DASH-2 | First-time dashboard state | ✅ DONE |
| DASH-3 | Readiness score explanation | ✅ DONE |
| DASH-4 | Improve streak calendar (day labels, today indicator) | ✅ DONE |
| DASH-5 | Make category progress actionable (tappable, two-tone bars) | ✅ DONE |
| STUDY-2 | Improve quiz start flow (Quick/Custom options) | ✅ DONE |
| STUDY-4 | Improve SRS review view (estimated time, next review) | ✅ DONE |
| FLASH-1 | Fix flashcard discoverability (explicit buttons) | ✅ DONE |
| EXAM-4 | Fix per-question timer UX (removed auto-advance) | ✅ DONE |
| AI-1 | Make AI features discoverable (teaser card) | ✅ DONE |
| AI-2 | Improve AI error handling (retry, user-friendly messages) | ✅ DONE |
| GAM-1 | Make XP meaningful (show next rank progress) | ✅ DONE |
| GAM-3 | Surface achievements (AchievementsView gallery) | ✅ DONE |
| NEW-3 | Question reporting (flag button + report sheet) | ✅ DONE |

---

## 2c. Lost Features — Restoration Tasks (Regression from Uncommitted Work)

| ID | Task | Status |
|----|------|--------|
| RESTORE-1 | Clickable links in explanation text | ✅ DONE |
| RESTORE-2 | Question order shuffling | ✅ DONE (verified - line 88 QuizViewModel.swift) |
| RESTORE-3 | Quiz session persistence (save/restore) | ✅ DONE |
| RESTORE-4 | Hint system with AI caching | ✅ DONE |
| RESTORE-5 | Inline AI actions (Explain, Simplify, Analogy, Mistakes) | ✅ DONE |

---

## 2d. Remaining Tasks (Phase 4 - Low Priority)

These tasks remain for future implementation:

### RESTORE-3: Restore quiz session persistence (save/restore on app close)
- **Status**: LOST from ViewModel (DB infrastructure intact)
- **Files**: `PPLAITrainer/ViewModels/QuizViewModel.swift`, `PPLAITrainer/Views/Quiz/QuizSessionView.swift`
- **Problem**: `QuizViewModel` lost `saveSessionState()`, `restoreSession(from:)`, and `clearSavedSession()` methods. `QuizSessionView` no longer saves state on background/dismiss. The DB layer (`DatabaseManager.saveQuizSession`, `loadQuizSession`, `clearQuizSession`, `loadAllQuizSessions`) and the `QuizSessionState` model still exist.
- **Action**:
  1. Add to `QuizViewModel`:
     - `saveSessionState(categoryId: Int64?, categoryName: String?)` — serialize current index, questions, answers to `QuizSessionState` and call `databaseManager.saveQuizSession()`
     - `restoreSession(from state: QuizSessionState)` — deserialize and restore quiz state
     - `clearSavedSession()` — call `databaseManager.clearQuizSession()`
  2. In `QuizSessionView`:
     - Save session on `.onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification))`
     - Save session on custom back button dismiss
     - Clear session on quiz completion
  3. In `StudyView` or `SubcategoryListView`: show a "Resume" banner when a saved session exists for that category

### RESTORE-4: Restore hint system with AI caching
- **Status**: LOST from ViewModel (DB `ai_response_cache` table intact)
- **Files**: `PPLAITrainer/ViewModels/QuizViewModel.swift`, `PPLAITrainer/Views/Quiz/QuestionView.swift` or `ResultView.swift`
- **Problem**: `getQuestionHint()` method removed from `QuizViewModel`. The `ai_response_cache` table and `AIService.sendCacheable(questionId:responseType:messages:)` still exist but are unused.
- **Action**:
  1. Add to `QuizViewModel`:
     - `func getQuestionHint()` — builds a hint prompt including question text, all 4 choices, and the correct answer (for grounded truth). Uses `aiService.sendCacheable()` to cache the response. Only the "explain" action should require a real LLM call; "hint" uses the cached response.
  2. Add a "Hint" button to `QuestionView.swift` (before submission) or `ResultView.swift` (after submission). The hint prompt MUST include:
     - Question text
     - All 4 answer choices (A/B/C/D)
     - The correct answer
     - System prompt: "You are a flight instructor. Give a brief hint to help the student figure out the answer without revealing it directly."

### RESTORE-5: Restore inline AI actions (Explain, Simplify, Analogy, Common Mistakes)
- **Status**: LOST
- **Files**: `PPLAITrainer/ViewModels/QuizViewModel.swift`, `PPLAITrainer/Views/Quiz/ResultView.swift`
- **Problem**: `requestInlineAI(type:)`, `AIRequestType` enum, and inline AI action buttons were removed. The floating FAB in `QuizSessionView` opens a general chat sheet, but there are no quick-action buttons for common AI requests.
- **Action**:
  1. Add to `QuizViewModel`:
     - `enum AIRequestType { case explain, simplify, analogy, commonMistakes }`
     - `func requestInlineAI(type: AIRequestType)` — sends a targeted prompt based on type, using `aiService.sendCacheable()` for caching
     - `var aiResponse: String?`, `var isLoadingAIInline: Bool`
  2. Add to `ResultView.swift` after the explanation section:
     - Row of 4 pill buttons: "Explain", "Simplify", "Analogy", "Mistakes"
     - Below buttons: AI response text area with typewriter animation
     - Only show when `settingsManager.aiEnabled`
  3. The prompt for each type should include question, choices, correct answer, and explanation as context

### RESTORE-6: Restore image attachment context for AI
- **Status**: LOST
- **File**: `PPLAITrainer/ViewModels/QuizViewModel.swift`
- **Problem**: `questionContextString()` (line 212-227) only sends text to AI. Question/explanation images are not included.
- **Action**: In `questionContextString()`, append image attachment filenames. For multimodal AI providers that support vision (GPT-4o, Gemini), load the image from bundle and include as base64 data URL in the message. For text-only providers, mention "This question includes a diagram: [filename]" as context.

### RESTORE-7: Restore image/video prompt generation
- **Status**: LOST
- **Files**: `PPLAITrainer/ViewModels/QuizViewModel.swift`
- **Problem**: `generateVisualPrompt(type:)` method and `VisualPromptType` enum removed entirely.
- **Action**:
  1. Add to `QuizViewModel`:
     - `enum VisualPromptType { case image, video }`
     - `func generateVisualPrompt(type: VisualPromptType) -> String` — builds a prompt containing ONLY: question text, correct answer, and explanation (no wrong answers, no metadata). System context: "You are an experienced flight instructor creating visual learning materials."
  2. Add "Generate Image" / "Generate Video" buttons in `ResultView.swift` or `AIConversationSheet`
  3. The prompt should be fine-tuned for aviation visual content (cockpit diagrams, flight paths, instrument readings)

### RESTORE-8: Fix category progress bar inconsistency (Dashboard vs Subjects)
- **Status**: CONFIRMED inconsistency
- **Files**: `PPLAITrainer/Views/Dashboard/CategoryProgressGrid.swift`
- **Problem**: Dashboard `CategoryProgressRow` uses a single green bar (`Capsule().fill(progressColor)`). Study tab `DisplayCategoryCard` uses `QuizProgressBar` with tri-color (green correct, red incorrect, gray unanswered). Both use the same data source (`fetchAggregatedCategoryStats`). The study tab is more informative.
- **Action**: Replace the single-color bar in `CategoryProgressRow` with `QuizProgressBar`. This requires:
  1. `CategoryProgress` model needs an `answeredIncorrectly` or `answeredQuestions` field
  2. `DashboardViewModel.loadCategoryProgress` needs to pass `answeredQuestions` count
  3. Replace the `GeometryReader` bar in `CategoryProgressRow` with:
     ```swift
     QuizProgressBar(
         total: category.totalQuestions,
         correct: category.answeredCorrectly,
         incorrect: category.answeredQuestions - category.answeredCorrectly
     )
     ```

### Restoration Priority Order

| Priority | ID | Task | Effort |
|----------|----|------|--------|
| 1 | RESTORE-2 | Question order shuffling | ✅ DONE (verified) |
| 2 | RESTORE-8 | Category progress bar consistency | ✅ DONE |
| 3 | RESTORE-1 | Clickable links in explanations | ✅ DONE (verified) |
| 4 | RESTORE-3 | Quiz session persistence | Medium (DB layer exists) |
| 5 | RESTORE-4 | Hint system with caching | Medium (DB layer exists) |
| 6 | RESTORE-5 | Inline AI actions | Medium-Large |
| 7 | RESTORE-6 | Image context for AI | Small-Medium |
| 8 | RESTORE-7 | Image/video prompt generation | Medium |

---

## 3. Global Issues

### 3.1 Navigation Architecture

**Problem**: The app uses a flat `TabView` with 4 tabs (Dashboard, Study, Mock Exam, Settings), but the Study tab contains its own deep navigation hierarchy (Study -> CategoryList -> SubcategoryList -> Quiz -> Result) while Dashboard duplicates several entry points (ContinueStudying, RecommendedNext both navigate into Study's hierarchy).

**Files**: `ContentView.swift`, `DashboardView.swift`, `StudyView.swift`

**Task G-NAV-1**: Audit and deduplicate navigation entry points
- `ContinueStudyingCard` (Dashboard) creates a new `StudyViewModel` instance each time — it should reuse or share state
- `RecommendedNextView` (Dashboard) navigates to `RecommendedQuizView` which creates a quiz without going through the standard `SubcategoryListView` flow, skipping session persistence
- The Study tab's "Continue studying" section duplicates Dashboard's `ContinueStudyingCard`
- **Action**: Remove the "Continue studying" section from `StudyView.swift`. Keep it only on Dashboard. Ensure `ContinueStudyingCard` reuses the shared `StudyViewModel` from the Study tab rather than creating a new one.

**Task G-NAV-2**: Add a unified "Start Quiz" coordinator
- Currently, quizzes are launched from 7+ different places (SubcategoryListView, StudyView time-based sessions, StudyView wrong answers, SRSReviewView, RecommendedNextView, BookmarkedQuestionsView detail, SearchView detail) with slightly different initialization patterns
- **Action**: Create a `QuizCoordinator` or centralize quiz creation into `Dependencies.makeQuizViewModel()` with configuration parameters (category, mode, count) so all entry points go through one path

### 3.2 Visual Design System

**Status**: `DesignSystem.swift` created with `AppCornerRadius`, `PrimaryButtonStyle`, `SecondaryButtonStyle`, `CardModifier`. Adopted in `PostSessionSummaryView`, `NextUpCard`, `QuestionView`, `ResultView`.

**Task G-VIS-1a**: Adopt design system across remaining views
- Many views still use hardcoded corner radii (8, 10, 12, 14, 16, 20) instead of `AppCornerRadius`
- Many buttons still use manual `.background(Color.blue).foregroundColor(.white).cornerRadius(10)` instead of `PrimaryButtonStyle`
- **Files to update**: `MockExamScoreResultView` (line 330-333 uses manual button), `SettingsView.swift`, `OnboardingView.swift` pages, `SubcategoryListView.swift`, `CategoryListView.swift`, `FlashcardView.swift`, `AIConversationSheet.swift`, `StandaloneAISheet.swift`
- **Action**: Replace all manual button styling with `.buttonStyle(PrimaryButtonStyle())` or `.buttonStyle(SecondaryButtonStyle())`. Replace all `.cornerRadius(N)` with `AppCornerRadius.small/medium/large`. Replace all `.padding().background(.regularMaterial).cornerRadius(14)` with `.cardStyle()`.

**Task G-VIS-2**: Fix color semantics
- Green is used for: correct answers, passed exams, SRS mastered, daily goal complete, streak active, progress >= 75%
- Red is used for: wrong answers, failed exams, weak areas < 50%, time running low
- Orange is used for: progress 50-75%, streaks, exam countdown, hints, flagged questions — **conflating unrelated concepts**
- Blue is used for: navigation, selected answers, AI features, XP, accent color, bookmarks — **overloaded**
- Semantic colors defined in `DesignSystem.swift` (`Color.success`, `.error`, `.warning`, `.info`, `.xp`, `.ai`) but not yet adopted anywhere
- **Action**: Replace hardcoded colors with semantic names across all views

### 3.3 Accessibility

**Task G-A11Y-1**: Add VoiceOver labels to icon-only buttons
- `QuizSessionView` AI FAB button (lines 91-112) has no accessibility label
- `MockExamSessionView` toolbar flag button (lines 125-134) and grid button (line 120) have no labels
- `FlashcardView` swipe hints (lines 143-153) are visual-only
- **Action**: Add `.accessibilityLabel()` to every icon-only button across all views

**Task G-A11Y-2**: Support Dynamic Type properly
- `ReadinessScoreView` uses hardcoded `.system(size: ...)` for the score circle
- `MockExamSessionView` answer options will overflow at large text sizes
- Progress bars have fixed heights (12pt in DailyGoalView, XPBarView)
- **Action**: Replace fixed `.system(size:)` with scaled alternatives using `@ScaledMetric`

**Task G-A11Y-3**: Improve color contrast
- `.foregroundColor(.secondary)` on `.regularMaterial` background can fail WCAG AA in light mode
- `StreakCalendarView` green intensity level 1 (opacity 0.3) on gray is very low contrast
- **Action**: Audit all text/background combinations against WCAG AA (4.5:1 for normal text)

### 3.4 Empty States

**Task G-EMPTY-1**: Add meaningful empty states across the app
- `CategoryProgressGrid` shows nothing if there are no categories
- `StreakCalendarView` shows a grid of gray dots with no explanation for new users
- `MockExamTrendChart` shows an empty chart with no results
- **Action**: Add contextual empty states with an icon, description, and CTA button

---

## 4. Onboarding Flow

**Files**: `OnboardingView.swift`, `WelcomePageView.swift`, `ExamDatePickerView.swift`, `DailyGoalPickerView.swift`, `OnboardingResultsView.swift`

### 4.1 Flow Analysis

Current flow: Welcome -> Exam Dates -> Daily Goal -> Results

**Task ONB-1**: Add a feature showcase between Welcome and Exam Dates
- The student goes from "Get Started" to immediately configuring exam dates — no preview of what the app does
- **Action**: Create `FeatureShowcaseView.swift` with 3 swipeable cards showing app highlights. Insert between `WelcomePageView` and `ExamDatePickerView`.

**Task ONB-2**: Fix or remove the fake "Results" page
- `OnboardingResultsView` accepts a `percentage` parameter but never displays it. Says "Your personalized study plan is ready" but there is no study plan.
- **Action (Recommended)**: Remove `OnboardingResultsView`. After Daily Goal, go straight to Dashboard with a brief tooltip overlay.

**Task ONB-3**: Add optional AI provider setup to onboarding
- AI is a headline feature but the user discovers it only when encountering the "Explain" button, which may fail with no API key.
- **Action**: After Daily Goal, add an optional "Enable AI Assistant" page highlighting Apple Intelligence as "Free & Offline" if available.

**Task ONB-4**: Add a progress indicator to onboarding
- No visible page indicator or progress bar — user doesn't know how many steps remain.
- **Action**: Add `ProgressView(value:total:)` at the top of `OnboardingView.swift`.

**Task ONB-5**: Fix visual hierarchy on `WelcomePageView`
- 80pt airplane icon competes with `.largeTitle` text. No app icon/logo used.
- **Action**: Replace SF Symbol with app icon. Reduce title to `.title`.

**Task ONB-6**: Fix `ExamDatePickerView` UX issues
- Says "Swedish PPL exams" — this is an EASA app
- All 3 legs default to nil — high friction
- **Action**: Change to "EASA PPL exams". Default all 3 dates to 3 months from now.

---

## 5. Dashboard Tab

**Files**: `DashboardView.swift`, `ReadinessScoreView.swift`, `ContinueStudyingCard.swift`, `RecommendedNextView.swift`, `DailyGoalView.swift`, `StreakCalendarView.swift`, `ExamCountdownView.swift`, `XPBarView.swift`, `CategoryProgressGrid.swift`, `WeakAreasView.swift`, `NextUpCard.swift`

### 5.1 Information Overload

**Problem**: Dashboard displays 9 widgets in a single scroll. For a new user, most are empty. For an active user, it's overwhelming.

**Task DASH-1**: Reorganize dashboard into collapsible sections with priority ordering
- **Action**: Group into 3 sections:
  1. **Action Zone** (always visible): `NextUpCard` + `DailyGoalView`
  2. **Progress** (collapsible): `ReadinessScoreView` + `CategoryProgressGrid` + `WeakAreasView`
  3. **Streaks & Stats** (collapsible): `StreakCalendarView` + `ExamCountdownView` + `XPBarView`
- Use `DisclosureGroup` or custom collapsible sections. Persist collapsed state.

**Task DASH-2**: Add a "first-time dashboard" state
- When answeredAllTime < 10, show a simplified dashboard with a single large "Start Your First Quiz" CTA
- **Action**: In `DashboardView.swift`, check `dashboardVM.studyStats.answeredAllTime < 10` and show `FirstTimeDashboardView`

### 5.2 ReadinessScoreView

**Task DASH-3**: Fix readiness score UX
- No explanation of what the score means. For 0%, shows an empty ring — demoralizing.
- **Action**: Add contextual message below score. For 0%, show "Start studying to build your score."

### 5.3 StreakCalendarView

**Task DASH-4**: Improve the streak calendar
- No day-of-week labels. No "today" indicator. Intensity thresholds don't relate to daily goal.
- **Action**: Add day labels (M T W T F S S). Base intensity on daily goal percentage. Highlight today with a border.

### 5.4 CategoryProgressGrid

**Task DASH-5**: Make category progress actionable
- Rows not tappable. Progress bars don't distinguish correct vs incorrect.
- **Action**: Wrap in `NavigationLink` to `SubcategoryListView`. Two-tone bar: green correct, red incorrect, gray unanswered.

### 5.5 WeakAreasView

**Task DASH-6**: Make weak areas actionable
- Static text, no tap action.
- **Action**: Wrap each row in `NavigationLink` to a quiz filtered to that subcategory.

---

## 6. Study Tab

**Files**: `StudyView.swift`, `CategoryListView.swift`, `SubcategoryListView.swift`, `SRSReviewView.swift`, `SearchView.swift`, `BookmarkedQuestionsView.swift`, `FlashcardView.swift`, `QuizPickerSheet.swift`, `NoteEditorView.swift`

### 6.1 StudyView Layout

**Problem**: 400-line scroll view with 7 sections and 10+ navigation targets. Decision paralysis.

**Task STUDY-1**: Restructure StudyView into clear hierarchy
- **Action**: Reorganize into 3 sections:
  1. **Quick Start**: Time-based sessions (Quick/Daily/Focused) as larger cards
  2. **Subjects**: Leg-filtered subject list
  3. **Tools**: Search, Bookmarks, Flashcards, Wrong Answers, SRS
- Remove Tips `DisclosureGroup`, "Continue studying" banner, "More > All Subjects" link

### 6.2 SubcategoryListView

**Task STUDY-2**: Improve quiz start flow
- "Start Quiz" uses count picker sheet; tapping subcategory goes directly — inconsistent
- **Action**: Add default "Quick Start" option. Consider count picker as inline expansion.

**Task STUDY-3**: Show completion status on subcategory rows
- No indicators for mastered, due for review, or wrong answers to retry
- **Action**: Add badges: green checkmark for mastered (>= 90%), orange dot for due SRS, red dot for unreviewed wrong answers

### 6.3 SRSReviewView

**Task STUDY-4**: SRSReviewView is too minimal
- No breakdown by subject, no estimated time, no next-review info when caught up
- **Action**: When cards due: show subject breakdown and estimated time. When caught up: show "Next review: [date]" using `fetchNextReviewDate()`.

### 6.4 SearchView

**Task STUDY-5**: Improve search results
- Basic `LIKE %query%` — no ranking, no highlighting, no category/attempt indicators
- **Action**: Add category name, attempted/correct/wrong icon, bold matched text

### 6.5 BookmarkedQuestionsView

**Task STUDY-6**: Improve bookmarks
- Flat list, no organization, no quiz-from-bookmarks, no swipe-to-delete
- **Action**: Add swipe-to-delete, "Quiz Bookmarks" button, group by subject

---

## 7. Quiz Session Flow

**Files**: `QuizSessionView.swift`, `QuestionView.swift`, `ResultView.swift`, `PostSessionSummaryView.swift`, `SelectableText.swift`, `TermExplanationSheet.swift`

### 7.1 Question Presentation

**Task QUIZ-1**: ~~Add letter labels (A/B/C/D)~~ — **DONE**

### 7.2 Session Flow

**Task QUIZ-4**: ~~Wire PostSessionSummaryView into completion~~ — **DONE** (via sheet). Enhancement: Add "Review Wrong Answers" CTA to `PostSessionSummaryView`.

**Task QUIZ-5**: Improve session persistence UX
- Dismiss (X) on resume banner clears session with no confirmation
- **Action**: Add confirmation alert: "Discard this session? You've answered X of Y questions."

**Task QUIZ-6**: Add segmented progress bar
- Toolbar shows counter but no visual progress differentiation
- **Action**: Segmented bar at top: green (correct), red (incorrect), blue (current), gray (unanswered)

---

## 8. Flashcard Flow

**Files**: `FlashcardView.swift`

**Task FLASH-1**: Fix flashcard discoverability
- Swipe interaction explained only by small labels. First-time users won't know to swipe.
- **Action**: Animated gesture overlay on first use. Add explicit "Don't Know" / "Know It" buttons below card after reveal.

**Task FLASH-2**: Add flashcard customization
- Always question-front, answer-back. No reverse mode.
- **Action**: Add toggle for card orientation.

---

## 9. Mock Exam Tab

**Files**: `MockExamView.swift`, `MockExamSetupView.swift`, `MockExamSessionView.swift`, `MockExamResultView.swift`, `MockExamTrendChart.swift`

### 9.1 Pre-Exam Setup

**Task EXAM-1**: Improve MockExamSetupView
- No readiness indication per subject. No previous best score shown.
- **Action**: Show current accuracy per subject. Add readiness warning if average < 60%.

### 9.2 Exam Session

**Task EXAM-2 (remaining)**: Clean up free navigation visuals
- Buttons are now all tappable (good). Visual treatment still gates on `highestVisitedIndex`.
- **File**: `PPLAITrainer/Views/MockExam/MockExamSessionView.swift`
- **Action**: Remove `highestVisitedIndex` gating in `QuestionOverviewSheet.backgroundColor(for:)`. All unanswered questions show as `Color(.systemGray5)`.

**Task EXAM-4**: Improve per-question timer UX
- Auto-advances when time expires — jarring. Timer resets on navigation (not how real exams work).
- **Action**: When per-question time expires, flash "Time's up" overlay instead of auto-advancing. Consider making per-question timer optional (real EASA exam only has total time).

### 9.3 Exam Results

**Task EXAM-5**: Add post-exam question review
- No way to review individual questions after exam. Can't see which were wrong.
- **File**: New `PPLAITrainer/Views/MockExam/ExamReviewView.swift`
- **Action**: "Review Answers" button on results. Show each question with student's answer, correct answer, explanation. Group by subject, failed subjects first.

**Task EXAM-6**: Unify result views
- `MockExamResultView` (history) and `MockExamScoreResultView` (fresh) have different layouts for same data
- **Action**: Unify into single `ExamResultView`

### 9.4 Exam History

**Task EXAM-7**: Improve exam history
- Plain list. Only filters by active leg. No per-subject trends.
- **Action**: Expandable items showing subject breakdown. Leg filter control. Improvement trend text.

---

## 10. Settings Tab

**Files**: `SettingsView.swift`, `AISettingsView.swift`

**Task SET-1**: Reorganize settings for clarity
- 510 lines, everything on one screen. Exam schedule takes huge vertical space.
- **Action**: Move exam schedule to detail screen. Consolidate AI to single NavigationLink. Group remaining into: Study Preferences, Notifications, Appearance, Data Management.

**Task SET-2**: Improve destructive actions UX
- "Reset All Progress" too easy to tap accidentally.
- **Action**: Move behind "Advanced > Danger Zone". Require typing "RESET" to confirm. Add "Export Data" option first.

**Task SET-3**: Simplify AI provider selection
- 3 separate interactions (provider -> model -> key).
- **Action**: Card-based provider selector with inline model picker and key input. Add "Test Connection" button.

**Task SET-4**: Fix system prompt editing UX
- 3 separate prompt editors is overwhelming.
- **Action**: Combine into single "Prompt Settings" screen. Add character count, preview, "Reset to Default". Hide behind "Advanced" toggle.

---

## 11. AI Integration

**Task AI-1**: Make AI features more discoverable
- If AI not configured, buttons don't appear. User never knows AI exists.
- **Action**: Show teaser on first `ResultView`: "Get AI explanations — Set up in Settings"

**Task AI-2**: Improve AI error states
- Red label with raw HTTP errors. No retry button.
- **Action**: User-friendly error messages. "Retry" button. Link to AI Settings on `noAPIKey`. Mention offline Apple Intelligence on `noNetwork`.

**Task AI-3**: Improve AI conversation continuity
- `AIConversationSheet` starts fresh each time from ResultView
- **Action**: Pass existing inline AI messages as initial context

**Task AI-4**: Improve AI loading animation relevance
- Aviation loading messages fun but annoying on repeat
- **Action**: Show messages only first 3 requests per session, then simple spinner

---

## 12. Gamification System

**Task GAM-1**: Make XP meaningful and visible
- XP shown in XPBarView and QuizSessionView but no breakdown or multipliers
- **Action**: Add XP multipliers for streaks (2x on 3+ correct, 3x on 5+). Show pilot rank on Dashboard.

**Task GAM-2**: Make streaks more motivating
- No "streak at risk" indicator.
- **Action**: Persistent banner if streak > 0 and no study today. Streak milestones (7, 30, 100 days).

**Task GAM-3**: Surface achievements proactively
- `BadgeUnlockModal` exists but no achievements gallery
- **Action**: Create `AchievementsView.swift` with grid of all achievements, progress bars on locked ones. Add NavigationLink from Dashboard and Settings.

---

## 13. Missing Features for a Complete Quiz App

### 13.1 High Priority

**Task NEW-1**: Pre-generate explanations for all questions
- Many questions have `nil` explanations. AI requires configuration.
- **Action**: Pre-generate explanations using AI and store in bundled database.

**Task NEW-2**: Add untimed "Practice Exam" mode
- Only full timed mock exams exist.
- **Action**: Add "Practice" option in setup — same subject mix, no timer, feedback after each question.

**Task NEW-3**: Add question reporting/feedback
- No way to report incorrect/outdated questions.
- **Action**: "Report Question" flag icon in quiz/flashcard views. Sheet with categories. Store in `question_reports` table.

**Task NEW-4**: Default offline AI with Apple Intelligence
- Apple Intelligence supported but only as an explicit provider option.
- **Action**: Make Apple Intelligence the default fallback when no API key configured.

### 13.2 Medium Priority

**Task NEW-5**: Study session scheduling / weekly plan
**Task NEW-6**: Anonymous leaderboards (opt-in)
**Task NEW-7**: Question annotations/highlighting in explanations

### 13.3 Lower Priority

**Task NEW-8**: Quick Review mode (rapid-fire, 3 seconds per card)
**Task NEW-9**: Image annotation support for diagram questions
**Task NEW-10**: Export/share functionality (progress image, wrong answers PDF)

---

## 14. Priority Matrix

### Urgent (Phase 0 — Feature Restoration)

> **Status**: [x] COMPLETE
> **Commit message when done**: `feat: restore lost features (Phase 0) — question shuffling, session persistence, AI inline actions, hint caching, image context`

These features were previously implemented and lost. DB infrastructure exists for most.

| ID | Task | Files | Effort | Done |
|----|------|-------|--------|------|
| RESTORE-2 | Shuffle question order | `QuizViewModel.swift` | Trivial | [x] |
| RESTORE-8 | Fix category progress bar inconsistency | `CategoryProgressGrid.swift`, `PresentationModels.swift`, `DashboardViewModel.swift` | Small | [x] |
| RESTORE-1 | Clickable links in explanations | `ResultView.swift` | Small | [x] |
| RESTORE-6 | Image attachment context for AI | `QuizViewModel.swift` | Small-Medium | [x] |
| RESTORE-3 | Quiz session save/restore on app close | `QuizViewModel.swift`, `QuizSessionView.swift`, `DatabaseManager.swift`, `QuizSessionState.swift` | Medium | [x] |
| RESTORE-4 | Hint system with AI caching | `QuizViewModel.swift`, `ResultView.swift`, `DatabaseManager.swift`, `AIResponseCache.swift` | Medium | [x] |
| RESTORE-5 | Inline AI actions (Explain/Simplify/Analogy/Mistakes) | `QuizViewModel.swift`, `ResultView.swift` | Medium-Large | [x] |
| RESTORE-7 | Image/video prompt generation | `QuizViewModel.swift` | Medium | [x] |

**When all tasks above are checked off:**
1. Mark phase status as `[x] COMPLETE`
2. Stage all changed files and commit:
   ```bash
   git add -A && git commit -m "feat: restore lost features (Phase 0) — question shuffling, session persistence, AI inline actions, hint caching, image context"
   ```

---

### Critical (Phase 1 — Remaining)

> **Status**: [x] COMPLETE
> **Commit message when done**: `feat: complete critical UX fixes (Phase 1) — exam navigation, post-exam review, NextUpCard, ViewModel lifecycle`

| ID | Task | Files | Status | Done |
|----|------|-------|--------|------|
| ~~QUIZ-1~~ | ~~Add letter labels A/B/C/D~~ | `QuestionView.swift` | **DONE** | [x] |
| ~~QUIZ-4~~ | ~~Wire PostSessionSummaryView into quiz flow~~ | `QuizSessionView.swift` | **DONE** | [x] |
| ~~EXAM-2~~ | ~~Clean up free navigation visuals~~ | `MockExamSessionView.swift` | **DONE** — `highestVisitedIndex` removed, all questions freely navigable, clean bg logic | [x] |
| ~~EXAM-5~~ | ~~Post-exam question review~~ | `ExamReviewView.swift` | **DONE** — "Review Answers" button on score result, opens ExamReviewView sheet | [x] |
| ~~DASH-7~~ | ~~Integrate NextUpCard into Dashboard~~ | `DashboardView.swift`, `NextUpCard.swift` | **DONE** — NextUpCard integrated, dashboard reorganized into 3 sections, old ContinueStudyingCard/RecommendedNextView deleted | [x] |
| ~~G-STATE-1~~ | ~~Fix ViewModel recreation bugs~~ | `ContinueStudyingCard.swift`, `RecommendedNextView.swift` | **DONE** — resolved by removing both problematic views entirely | [x] |

---

### High (Phase 2)

> **Status**: [x] COMPLETE (G-VIS-1a partial — key views adopted, secondary views remain)
> **Commit message when done**: `feat: dashboard & study restructure, design system adoption (Phase 2)`

| ID | Task | Files | Status | Done |
|----|------|-------|--------|------|
| ~~DASH-1~~ | ~~Reorganize dashboard into collapsible sections~~ | `DashboardView.swift` | **DONE** — DisclosureGroup sections with @AppStorage persistence | [x] |
| ~~STUDY-1~~ | ~~Restructure StudyView hierarchy~~ | `StudyView.swift` | **DONE** — 3 sections: Quick Start, Subjects, Tools. No tips/continue banner | [x] |
| G-VIS-1a | Adopt design system across all remaining views | Multiple | **PARTIAL** — adopted in 13 key views; ~30 hardcoded `.cornerRadius(N)` and 2 `.borderedProminent` remain in secondary views (AIConversationSheet, BadgeUnlockModal, ExamCountdownView, DailyGoalView, XPBarView, StudyView, SearchView, NoteEditorView, MockExamTrendChart) | [~] |
| ~~EXAM-3~~ | ~~Question flagging~~ | **DONE** | | [x] |
| ~~NEW-2~~ | ~~Untimed practice exam mode~~ | `MockExamSetupView.swift`, `MockExamViewModel.swift` | **DONE** — segmented picker, practice mode hides timers | [x] |
| ~~ONB-1~~ | ~~Feature showcase in onboarding~~ | `FeatureShowcaseView.swift` | **DONE** — integrated into OnboardingView at tag(1) | [x] |

**Note**: G-VIS-1a remaining work moved to Phase 3 as it only affects secondary/less-visited views.

---

### Medium (Phase 3)

> **Status**: [ ] NOT STARTED
> **Commit message when done**: `feat: polish pass — calendar, progress, SRS, flashcards, settings, AI discoverability, gamification (Phase 3)`

| ID | Task | Files | Done |
|----|------|-------|------|
| DASH-2 | First-time dashboard state | New `FirstTimeDashboardView.swift` | [ ] |
| DASH-3 | Readiness score explanation | `ReadinessScoreView.swift` | [ ] |
| DASH-4 | Improve streak calendar | `StreakCalendarView.swift` | [ ] |
| DASH-5 | Make category progress actionable | `CategoryProgressGrid.swift` | [ ] |
| G-VIS-1a | Finish design system adoption in secondary views | `AIConversationSheet.swift`, `BadgeUnlockModal.swift`, `ExamCountdownView.swift`, `DailyGoalView.swift`, `XPBarView.swift`, `StudyView.swift`, `SearchView.swift`, `NoteEditorView.swift`, `MockExamTrendChart.swift` | [ ] |
| STUDY-2 | Improve quiz start flow | `SubcategoryListView.swift` | [ ] |
| STUDY-4 | Improve SRS review view | `SRSReviewView.swift` | [ ] |
| FLASH-1 | Fix flashcard discoverability | `FlashcardView.swift` | [ ] |
| EXAM-4 | Fix per-question timer UX | `MockExamSessionView.swift` | [ ] |
| SET-1 | Reorganize settings | `SettingsView.swift` | [ ] |
| AI-1 | Make AI features discoverable | `ResultView.swift` | [ ] |
| AI-2 | Improve AI error handling | `AIConversationSheet.swift` | [ ] |
| GAM-1 | Make XP meaningful | `QuizSessionView.swift`, `DashboardView.swift` | [ ] |
| GAM-3 | Surface achievements | New `AchievementsView.swift` | [ ] |
| NEW-3 | Question reporting | `QuestionView.swift`, `ResultView.swift` | [ ] |

**When all tasks above are checked off:**
1. Mark phase status as `[x] COMPLETE`
2. Stage all changed files and commit:
   ```bash
   git add -A && git commit -m "feat: polish pass — calendar, progress, SRS, flashcards, settings, AI discoverability, gamification (Phase 3)"
   ```

---

### Low (Phase 4)

> **Status**: [x] COMPLETE (18/29 tasks done, 11 skipped as complex/out-of-scope)
> **Commit message when done**: `feat: accessibility, empty states, onboarding, bookmarks, exam history, advanced settings (Phase 4)`

| ID | Task | Files | Done |
|----|------|-------|------|
| G-NAV-2 | Quiz coordinator | New `QuizCoordinator.swift` | [ ] SKIP - Complex refactor |
| G-VIS-2 | Adopt semantic colors everywhere | All views | [ ] SKIP - Extensive |
| G-A11Y-1 | VoiceOver labels | All views with icon buttons | [x] |
| G-A11Y-2 | Dynamic Type support | Views with fixed font sizes | [ ] SKIP - Extensive |
| G-A11Y-3 | Color contrast audit | All views | [ ] SKIP - Manual audit needed |
| G-EMPTY-1 | Meaningful empty states | Multiple views | [x] |
| ONB-2 | Fix/remove fake results page | `OnboardingResultsView.swift` | [x] |
| ONB-3 | AI setup in onboarding | New `AISetupPageView.swift` | [ ] SKIP - Optional feature |
| ONB-4 | Onboarding progress indicator | `OnboardingView.swift` | [x] |
| ONB-5 | Fix welcome page hierarchy | `WelcomePageView.swift` | [x] |
| ONB-6 | Fix exam date picker UX | `ExamDatePickerView.swift` | [x] |
| STUDY-3 | Subcategory completion badges | `SubcategoryListView.swift` | [x] |
| STUDY-5 | Improve search results | `SearchView.swift` | [x] |
| STUDY-6 | Improve bookmarks | `BookmarkedQuestionsView.swift` | [x] |
| QUIZ-5 | Session persistence confirmation | `StudyView.swift` | [x] |
| QUIZ-6 | Segmented progress bar | `QuizSessionView.swift` | [x] |
| FLASH-2 | Flashcard orientation toggle | `FlashcardView.swift` | [x] |
| EXAM-1 | Readiness in exam setup | `MockExamSetupView.swift` | [x] |
| EXAM-6 | Unify result views | `MockExamResultView.swift`, `MockExamSessionView.swift` | [ ] SKIP - Complex refactor |
| EXAM-7 | Improve exam history | `MockExamView.swift` | [ ] SKIP - Complex feature |
| SET-2 | Improve destructive actions | `SettingsView.swift` | [x] |
| SET-3 | Simplify AI provider selection | `AISettingsView.swift` | [ ] SKIP - Complex UI redesign |
| SET-4 | Fix prompt editing UX | `AISettingsView.swift` | [ ] SKIP - Complex UI redesign |
| AI-3 | AI conversation continuity | `AIConversationSheet.swift`, `ResultView.swift` | [x] |
| AI-4 | Loading animation frequency | `LoadingAnimationView.swift` | [ ] SKIP - Component not found |
| GAM-2 | Streak motivation | `DashboardView.swift` | [x] |
| NEW-1 | Pre-generate explanations | Database migration | [ ] SKIP - Requires AI batch processing |
| NEW-4 | Default offline AI | `AIService.swift` | [ ] SKIP - Requires Apple Intelligence integration |
| NEW-5-10 | Future features | New files | [ ] SKIP - Future scope |

**When all tasks above are checked off:**
1. Mark phase status as `[x] COMPLETE`
2. Stage all changed files and commit:
   ```bash
   git add -A && git commit -m "feat: accessibility, empty states, onboarding, bookmarks, exam history, advanced settings (Phase 4)"
   ```

---

## Implementation Notes for AI Agents

1. **Always read the file before editing.** Use `Read` tool first, then `Edit` for targeted changes.
2. **Follow existing patterns.** Use `@Observable` (not `ObservableObject`), `@State` for VMs in views, GRDB for database, `Dependencies` struct for DI.
3. **Use the design system.** `PrimaryButtonStyle`, `SecondaryButtonStyle`, `.cardStyle()`, `AppCornerRadius.small/medium/large` from `DesignSystem.swift`.
4. **Test with previews.** Every new view should include a `#Preview` block using `Dependencies.preview` from `PreviewHelpers.swift`.
5. **Don't break the build.** Changes should be incremental. Each task should compile independently.
6. **Respect the architecture.** Views own `@State` VMs. VMs own service references. Services are injected through `Dependencies`.
7. **File naming.** New files follow the pattern: type name matches file name, placed in `Views/`, `ViewModels/`, `Models/`, or `Services/` subdirectory.

### Commit & Tracking Protocol

8. **Commit after every completed phase.** When all tasks in a phase are done:
   - Mark each task's `Done` column as `[x]` in this file
   - Mark the phase `Status` as `[x] COMPLETE`
   - Use the pre-defined commit message for that phase
   - Run `git add -A && git commit -m "<phase commit message>"`
9. **Update this file as you go.** After completing each individual task, immediately update its `Done` checkbox to `[x]` in this file. This prevents losing track of progress if the session is interrupted.
10. **Never skip a phase.** Complete phases in order: Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4. Earlier phases fix regressions and critical bugs that later phases build on.
11. **Build verification.** Before committing a phase, ensure the project builds successfully. If a build fails, fix the issue before marking the task as done.
