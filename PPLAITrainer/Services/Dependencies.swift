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
    let activeDataset: DatasetDescriptor
    let activeProfileId: String
    let availableDatasets: [DatasetDescriptor]
    let questionAssetProvider: QuestionAssetProviding
    let switchDataset: (String) async throws -> Void
    

    var quizCoordinator: QuizCoordinator {
        QuizCoordinator(dependencies: self)
    }

    func makeQuizViewModel() -> QuizViewModel {
        QuizViewModel(
            databaseManager: databaseManager,
            srsEngine: srsEngine,
            aiService: aiService,
            settingsManager: settingsManager,
            gamificationService: gamificationService,
            hapticService: hapticService,
            soundService: soundService,
            questionAssetProvider: questionAssetProvider
        )
    }

    var isSelectedAIProviderConfigured: Bool {
        guard settingsManager.aiEnabled else { return false }
        let provider = AIProviderType(rawValue: settingsManager.selectedProvider) ?? .openai
        guard let apiKey = try? keychainStore.read(provider: provider.rawValue) else {
            return false
        }
        return !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
