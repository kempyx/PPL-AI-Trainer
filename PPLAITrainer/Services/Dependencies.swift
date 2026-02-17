import SwiftUI

struct Dependencies {
    let databaseManager: DatabaseManaging
    let srsEngine: SRSEngine
    let mockExamEngine: MockExamEngine
    let keychainStore: KeychainStore
    let settingsManager: SettingsManager
    let networkMonitor: NetworkMonitor
    let aiService: AIServiceProtocol
    let gamificationService: GamificationService
    let hapticService: HapticService
    let soundService: SoundService
    let notificationService: NotificationService
    
    func makeQuizViewModel() -> QuizViewModel {
        QuizViewModel(
            databaseManager: databaseManager,
            srsEngine: srsEngine,
            aiService: aiService,
            settingsManager: settingsManager,
            gamificationService: gamificationService,
            hapticService: hapticService,
            soundService: soundService
        )
    }
}

private struct DependenciesKey: EnvironmentKey {
    static let defaultValue: Dependencies? = nil
}

extension EnvironmentValues {
    var dependencies: Dependencies? {
        get { self[DependenciesKey.self] }
        set { self[DependenciesKey.self] = newValue }
    }
}
