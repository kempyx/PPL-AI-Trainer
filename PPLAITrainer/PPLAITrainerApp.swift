import SwiftUI

@main
struct PPLAITrainerApp: App {
    private static let inlineAICacheCleanupKey = "inlineAICacheCleanupV3"
    private static let staleInlineCacheResponseTypes = [
        "explain",
        "simplify",
        "analogy",
        "mistakes",
        "inline_v2_explain",
        "inline_v2_simplify",
        "inline_v2_analogy",
        "inline_v2_mistakes",
        "inline_v3_simplify",
        "inline_v3_analogy",
        "inline_v3_mistakes"
    ]

    let deps: Dependencies?
    let initError: String?

    init() {
        do {
            let databaseManager: DatabaseManaging = try DatabaseManager()
            let keychainStore = KeychainStore()
            let settingsManager = SettingsManager()
            let networkMonitor = NetworkMonitor()

            if !UserDefaults.standard.bool(forKey: Self.inlineAICacheCleanupKey) {
                try? databaseManager.clearAIResponseCache(responseTypes: Self.staleInlineCacheResponseTypes)
                UserDefaults.standard.set(true, forKey: Self.inlineAICacheCleanupKey)
            }
            
            let gamificationService = GamificationService(databaseManager: databaseManager, settingsManager: settingsManager)
            let hapticService = HapticService(settingsManager: settingsManager)
            let soundService = SoundService(settingsManager: settingsManager)
            let notificationService = NotificationService(settingsManager: settingsManager)

            self.deps = Dependencies(
                databaseManager: databaseManager,
                srsEngine: SRSEngine(),
                mockExamEngine: MockExamEngine(databaseManager: databaseManager),
                keychainStore: keychainStore,
                settingsManager: settingsManager,
                networkMonitor: networkMonitor,
                aiService: AIService(keychainStore: keychainStore, settingsManager: settingsManager, networkMonitor: networkMonitor),
                gamificationService: gamificationService,
                hapticService: hapticService,
                soundService: soundService,
                notificationService: notificationService
            )
            self.initError = nil
        } catch {
            self.deps = nil
            self.initError = error.localizedDescription
        }
    }

    var body: some Scene {
        WindowGroup {
            if let deps = deps {
                RootView(deps: deps)
            } else {
                DatabaseErrorView(error: initError ?? "Unknown error")
            }
        }
    }
}

private struct RootView: View {
    let deps: Dependencies
    @State private var hasCompletedOnboarding: Bool
    @State private var showSplash = true
    
    init(deps: Dependencies) {
        self.deps = deps
        self._hasCompletedOnboarding = State(initialValue: deps.settingsManager.hasCompletedOnboarding)
    }
    
    var body: some View {
        Group {
            if showSplash {
                SplashScreenView {
                    showSplash = false
                }
            } else if hasCompletedOnboarding {
                ContentView(deps: deps)
                    .onReceive(NotificationCenter.default.publisher(for: .didResetProgress)) { _ in
                        hasCompletedOnboarding = false
                    }
            } else {
                OnboardingView(viewModel: OnboardingViewModel(
                    databaseManager: deps.databaseManager,
                    settingsManager: deps.settingsManager,
                    notificationService: deps.notificationService
                )) {
                    hasCompletedOnboarding = true
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSplash)
    }
}

extension Notification.Name {
    static let didResetProgress = Notification.Name("didResetProgress")
    static let settingsDidChange = Notification.Name("settingsDidChange")
}

private struct DatabaseErrorView: View {
    let error: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("Unable to Load Database")
                .font(.title2.weight(.semibold))

            Text(error)
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("Try reinstalling the app. If the problem persists, contact support.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}
