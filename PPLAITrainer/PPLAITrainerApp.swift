import SwiftUI

@main
struct PPLAITrainerApp: App {
    let deps: Dependencies?
    let initError: String?

    init() {
        do {
            let databaseManager: DatabaseManaging = try DatabaseManager()
            let keychainStore = KeychainStore()
            let settingsManager = SettingsManager()
            let networkMonitor = NetworkMonitor()

            self.deps = Dependencies(
                databaseManager: databaseManager,
                srsEngine: SRSEngine(),
                mockExamEngine: MockExamEngine(databaseManager: databaseManager),
                keychainStore: keychainStore,
                settingsManager: settingsManager,
                networkMonitor: networkMonitor,
                aiService: AIService(keychainStore: keychainStore, settingsManager: settingsManager, networkMonitor: networkMonitor)
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
                ContentView(deps: deps)
            } else {
                DatabaseErrorView(error: initError ?? "Unknown error")
            }
        }
    }
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
