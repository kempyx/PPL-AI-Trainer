import SwiftUI

@main
struct PPLAITrainerApp: App {
    @State private var bootstrapper: AppBootstrapper?
    @State private var bootstrapInitError: String?

    init() {
        do {
            _bootstrapper = State(initialValue: try AppBootstrapper())
            _bootstrapInitError = State(initialValue: nil)
        } catch {
            _bootstrapper = State(initialValue: nil)
            _bootstrapInitError = State(initialValue: error.localizedDescription)
        }
    }

    var body: some Scene {
        WindowGroup {
            if let bootstrapper {
                BootstrapRootView(bootstrapper: bootstrapper)
            } else {
                DatabaseErrorView(error: bootstrapInitError ?? "Unknown error")
            }
        }
    }
}

private struct BootstrapRootView: View {
    @State private var bootstrapper: AppBootstrapper
    @State private var hasCompletedOnboarding: Bool
    @State private var showSplash = true

    init(bootstrapper: AppBootstrapper) {
        self._bootstrapper = State(initialValue: bootstrapper)
        self._hasCompletedOnboarding = State(
            initialValue: bootstrapper.deps?.settingsManager.hasCompletedOnboarding ?? false
        )
    }

    var body: some View {
        Group {
            if showSplash {
                SplashScreenView {
                    showSplash = false
                }
            } else {
                contentBody
                    .overlay {
                        if bootstrapper.isLoading && bootstrapper.deps == nil {
                            BootstrapLoadingView()
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSplash)
        .task {
            await bootstrapper.load()
            syncOnboardingState()
        }
        .onChange(of: bootstrapper.rootResetToken) { _, _ in
            syncOnboardingState()
        }
    }

    @ViewBuilder
    private var contentBody: some View {
        if let deps = bootstrapper.deps {
            if hasCompletedOnboarding {
                ContentView(deps: deps)
                    .id(bootstrapper.rootResetToken)
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
        } else {
            DatabaseErrorView(error: bootstrapper.initError ?? "Unknown error")
        }
    }

    private func syncOnboardingState() {
        guard let deps = bootstrapper.deps else { return }
        hasCompletedOnboarding = deps.settingsManager.hasCompletedOnboarding
    }
}

extension Notification.Name {
    static let didResetProgress = Notification.Name("didResetProgress")
    static let settingsDidChange = Notification.Name("settingsDidChange")
}

private struct BootstrapLoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text("Loading dataset…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
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
