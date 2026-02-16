# PPLAITrainer - Project Context for Claude

## What This App Is

PPLAITrainer is an iOS app for preparing students to pass their **EASA PPL (Private Pilot License) theory exams**. It contains 2,681 multiple-choice questions across 13 aviation subjects, with AI-powered explanations, spaced repetition, timed mock exams, and progress tracking.

## Target User

Student pilots studying for their PPL theory exams. They need to pass 13 subjects with 75%+ on each. Study typically spans 2-6 months. Users open the app daily in short sessions (10-30 min).

## Tech Stack

- **Language**: Swift (SwiftUI, iOS 17+)
- **Architecture**: MVVM with `@Observable` (not Combine-based ObservableObject)
- **Database**: SQLite via GRDB.swift (not Core Data, not SwiftData)
- **AI Providers**: OpenAI (gpt-4o-mini), Google Gemini (gemini-2.0-flash-lite), Grok (grok-3-mini)
- **DI**: Manual dependency injection via `Dependencies` struct, injected through SwiftUI environment
- **Secure Storage**: Keychain for API keys
- **Settings**: UserDefaults via `SettingsManager`

## Project Structure

```
PPLAITrainer/
  PPLAITrainerApp.swift          # App entry, dependency init
  ContentView.swift              # Tab bar: Dashboard, Study, Mock Exam, Settings

  Models/
    Question.swift               # Question, Category, Attachment, CategoryGroup
    PresentationModels.swift     # PresentedQuestion, CategoryStat, SRSStats, StudyStats, etc.
    AnswerRecord.swift           # Answer history records
    SRSCard.swift                # Spaced repetition card state
    StudyDay.swift               # Daily study activity
    MockExamResult.swift         # Exam results with category breakdown
    Mnemonic.swift               # User-saved mnemonics
    AIProviderConfig.swift       # API endpoints/models per provider

  Services/
    DatabaseManager.swift        # GRDB database, all SQL queries, protocol: DatabaseManaging
    SRSEngine.swift              # SM-2 spaced repetition algorithm
    MockExamEngine.swift         # Exam generation + scoring
    AIService.swift              # Multi-provider AI chat, protocol: AIServiceProtocol
    KeychainStore.swift          # Secure API key storage
    SettingsManager.swift        # UserDefaults wrapper
    NetworkMonitor.swift         # NWPathMonitor connectivity
    Dependencies.swift           # DI container + environment key

  ViewModels/
    DashboardViewModel.swift     # Dashboard data: readiness, streaks, weak areas
    StudyViewModel.swift         # Category browsing, SRS stats
    QuizViewModel.swift          # Quiz sessions, answer tracking, AI chat
    MockExamViewModel.swift      # Mock exam sessions, timing, scoring
    SettingsViewModel.swift      # Settings UI state

  Views/
    Dashboard/
      DashboardView.swift        # Main dashboard composition
      ReadinessScoreView.swift   # Animated circular score + stat pills
      StreakCalendarView.swift   # 28-day heatmap + streak counters
      CategoryProgressGrid.swift # Category progress bars
      WeakAreasView.swift        # Top 5 weakest subcategories
      StudyStatsView.swift       # DEAD CODE (stats moved to ReadinessScoreView)

    Study/
      StudyView.swift            # Study hub: SRS, wrong answers, categories
      CategoryListView.swift     # Top-level category cards + grouping
      SubcategoryListView.swift  # Subcategory rows + "Study All" button
      SRSReviewView.swift        # SRS review entry point

    Quiz/
      QuizSessionView.swift      # Main quiz UI: question + answer + result flow
      QuestionView.swift         # Question text + answer options + images
      ResultView.swift           # Correct/incorrect feedback + explanation + mnemonic
      AIResponseSheet.swift      # AI chat sheet with typewriter animation

    MockExam/
      MockExamView.swift         # Mock exam hub + history list
      MockExamSetupView.swift    # Pre-exam info + start button
      MockExamSessionView.swift  # Timed exam session UI
      MockExamResultView.swift   # Pass/fail result + category breakdown
      MockExamHistoryView.swift  # DEAD CODE (history inline in MockExamView)

    Settings/
      SettingsView.swift         # Provider picker, API keys, appearance

  Resources/
    153-en.sqlite                # Bundled question database (read-only source)
    QuestionImages/              # ~170 aviation images referenced by questions
```

## Database

The app copies `153-en.sqlite` from the bundle on first launch and applies migrations for user data tables. The bundled DB is read-only reference data.

### Schema (bundled, read-only)
- `questions` (2,681 rows) - id, category, text, correct, incorrect0-2, explanation, attachments
- `categories` (174 rows) - hierarchical: 13 top-level → subcategories. `parent` field links to parent.
- `attachments` - image references for questions
- `category_groups` - groups related top-level categories together

### Schema (user data, migrated at runtime)
- `answer_records` - every answer attempt (questionId, chosenAnswer, isCorrect, timestamp)
- `srs_cards` - SRS state per question (box 0-5, easeFactor, interval, nextReviewDate)
- `mnemonics` - AI-generated memory aids per question
- `mock_exam_results` - completed exam results with JSON category breakdown
- `study_days` - daily activity (date PK, questionsAnswered, correctAnswers)

## Key Patterns

### Dependency Injection
All services are created in `PPLAITrainerApp.init()` and passed through `Dependencies` struct via `.environment(\.dependencies)`. ViewModels receive services through `Dependencies`.

### Database Protocol
`DatabaseManaging` protocol abstracts all DB operations. `DatabaseManager` is the concrete implementation. This enables testing.

### SRS Algorithm
SM-2 variant: box 0-5, ease factor 1.3-3.0, intervals: 1d → 6d → multiplicative. Wrong answer resets to box 0.

### AI Chat
`QuizViewModel` manages AI chat state. Messages are `ChatMessage(role:content:)`. The system prompt is configurable in settings. AI responses use typewriter animation.

### Question Presentation
`PresentedQuestion.from(_:databaseManager:)` shuffles answer options and resolves attachments. Used by both QuizViewModel and MockExamViewModel.

## Known Bugs (see TASKS.md)

Prioritized list of 12 bugs/cleanups documented in TASKS.md. Most critical:
- Tasks 3 & 4: Answer stats use "ever correct/wrong" instead of latest attempt
- Tasks 1 & 2: Quiz and mock exam sessions have no completion/result screens
- Task 6: SRS stats broken for top-level categories (queries subcategory IDs)

## Conventions

- Use `@Observable` (Observation framework), NOT `ObservableObject`/`@Published`
- Use `@State` for view model references in views, NOT `@StateObject`
- Database operations throw and use GRDB's `dbPool.read/write` pattern
- All async work uses Swift concurrency (async/await), NOT completion handlers
- Navigation uses `NavigationStack` with `NavigationLink`
- Error handling: log with `Logger`, throw typed errors, show user-facing messages
- Date formatting: `DateFormatter.yyyyMMdd` static cached instance (after Task 10 fix)
- File names match the primary type they contain
