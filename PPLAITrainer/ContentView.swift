import SwiftUI

struct ContentView: View {
    let deps: Dependencies
    @State private var appearanceMode: String
    @State private var activeLeg: ExamLeg
    @State private var dashboardViewModel: DashboardViewModel
    @State private var studyViewModel: StudyViewModel
    @State private var mockExamViewModel: MockExamViewModel
    @State private var settingsViewModel: SettingsViewModel
    
    init(deps: Dependencies) {
        self.deps = deps
        self._appearanceMode = State(initialValue: deps.settingsManager.appearanceMode)
        self._activeLeg = State(initialValue: deps.settingsManager.activeLeg)
        
        let mockVM = MockExamViewModel(databaseManager: deps.databaseManager, mockExamEngine: deps.mockExamEngine, settingsManager: deps.settingsManager)
        mockVM.gamificationService = deps.gamificationService
        
        self._dashboardViewModel = State(initialValue: DashboardViewModel(databaseManager: deps.databaseManager, settingsManager: deps.settingsManager))
        self._studyViewModel = State(initialValue: StudyViewModel(databaseManager: deps.databaseManager, settingsManager: deps.settingsManager))
        self._mockExamViewModel = State(initialValue: mockVM)
        self._settingsViewModel = State(initialValue: SettingsViewModel(
            keychainStore: deps.keychainStore,
            settingsManager: deps.settingsManager,
            availableDatasets: deps.availableDatasets,
            activeDatasetId: deps.activeDataset.id,
            activeProfileId: deps.activeProfileId,
            switchDataset: deps.switchDataset
        ))
    }
    
    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
    var body: some View {
        TabView {
            DashboardView(viewModel: dashboardViewModel, studyViewModel: studyViewModel)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
            
            StudyView(viewModel: studyViewModel)
                .tabItem {
                    Label("Study", systemImage: "book.fill")
                }
            
            MockExamView(viewModel: mockExamViewModel)
                .tabItem {
                    Label("Mock Exam", systemImage: "doc.text.fill")
                }
            
            SettingsView(viewModel: settingsViewModel)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(activeLeg.color)
        .preferredColorScheme(colorScheme)
        .environment(\.dependencies, deps)
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            appearanceMode = deps.settingsManager.appearanceMode
            activeLeg = deps.settingsManager.activeLeg
        }
        .onReceive(NotificationCenter.default.publisher(for: .settingsDidChange)) { _ in
            Task {
                await rescheduleNotifications(deps: deps)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                await rescheduleNotifications(deps: deps)
            }
        }
    }
    
    private func rescheduleNotifications(deps: Dependencies) async {
        let dueCardCount = (try? deps.databaseManager.fetchDueCards(limit: nil).count) ?? 0
        let currentStreak = (try? deps.databaseManager.fetchCurrentStreak()) ?? 0
        let dailyGoalProgress = calculateDailyGoalProgress(deps: deps)
        let daysUntilExam = deps.settingsManager.nearestExamDate.flatMap { Calendar.current.dateComponents([.day], from: Date(), to: $0).day }
        
        await deps.notificationService.rescheduleAll(
            dueCardCount: dueCardCount,
            currentStreak: currentStreak,
            dailyGoalProgress: dailyGoalProgress,
            readinessScore: 0,
            daysUntilExam: daysUntilExam
        )
    }
    
    private func calculateDailyGoalProgress(deps: Dependencies) -> Double {
        let today = DateFormatter.yyyyMMdd.string(from: Date())
        guard let studyDays = try? deps.databaseManager.fetchStudyDays(from: today, to: today),
              let todayActivity = studyDays.first else {
            return 0
        }
        let target = deps.settingsManager.dailyGoalTarget
        return min(Double(todayActivity.questionsAnswered) / Double(target), 1.0)
    }
}
