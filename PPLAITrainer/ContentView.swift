import SwiftUI

struct ContentView: View {
    let deps: Dependencies
    @State private var appearanceMode: String
    
    init(deps: Dependencies) {
        self.deps = deps
        self._appearanceMode = State(initialValue: deps.settingsManager.appearanceMode)
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
            DashboardView(viewModel: DashboardViewModel(databaseManager: deps.databaseManager))
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
            
            StudyView(viewModel: StudyViewModel(databaseManager: deps.databaseManager))
                .tabItem {
                    Label("Study", systemImage: "book.fill")
                }
            
            MockExamView(viewModel: MockExamViewModel(databaseManager: deps.databaseManager, mockExamEngine: deps.mockExamEngine))
                .tabItem {
                    Label("Mock Exam", systemImage: "doc.text.fill")
                }
            
            SettingsView(viewModel: SettingsViewModel(keychainStore: deps.keychainStore, settingsManager: deps.settingsManager))
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .preferredColorScheme(colorScheme)
        .environment(\.dependencies, deps)
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            appearanceMode = deps.settingsManager.appearanceMode
        }
    }
}
