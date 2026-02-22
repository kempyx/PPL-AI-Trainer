import Foundation
import Observation

@MainActor
@Observable
final class AppBootstrapper {
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

    private let keychainStore: KeychainStore
    private let settingsManager: SettingsManager
    private let networkMonitor: NetworkMonitor
    private let datasetCatalog: DatasetCatalogManaging
    private let activeDatasetStore: ActiveDatasetStoring

    var deps: Dependencies?
    var initError: String?
    var isLoading = false
    var rootResetToken = UUID()

    init(
        keychainStore: KeychainStore? = nil,
        settingsManager: SettingsManager? = nil,
        networkMonitor: NetworkMonitor? = nil,
        datasetCatalog: DatasetCatalogManaging? = nil,
        activeDatasetStore: ActiveDatasetStoring? = nil
    ) throws {
        let resolvedKeychainStore = keychainStore ?? KeychainStore()
        let resolvedSettingsManager = settingsManager ?? SettingsManager()
        let resolvedNetworkMonitor = networkMonitor ?? NetworkMonitor()

        self.keychainStore = resolvedKeychainStore
        self.settingsManager = resolvedSettingsManager
        self.networkMonitor = resolvedNetworkMonitor

        if let datasetCatalog {
            self.datasetCatalog = datasetCatalog
        } else {
            self.datasetCatalog = try BundledDatasetCatalog()
        }

        if let activeDatasetStore {
            self.activeDatasetStore = activeDatasetStore
        } else {
            self.activeDatasetStore = ActiveDatasetStore(settingsManager: resolvedSettingsManager)
        }
    }

    func load() async {
        guard deps == nil, !isLoading else { return }
        await rebuildDependencies(resetRoot: false)
    }

    func switchDataset(to datasetId: String) async throws {
        guard let dataset = datasetCatalog.dataset(id: datasetId) else {
            throw NSError(domain: "AppBootstrapper", code: 1, userInfo: [NSLocalizedDescriptionKey: "Dataset not found: \(datasetId)"])
        }

        guard !isLoading else {
            throw NSError(domain: "AppBootstrapper", code: 2, userInfo: [NSLocalizedDescriptionKey: "Dataset switch already in progress"])
        }

        let profileId = activeDatasetStore.activeProfileId(for: dataset.id)

        isLoading = true
        defer { isLoading = false }

        let rebuiltDeps: Dependencies
        do {
            rebuiltDeps = try buildDependencies(dataset: dataset, profileId: profileId)
        } catch {
            throw NSError(domain: "AppBootstrapper", code: 3, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
        }

        activeDatasetStore.setActiveDatasetId(dataset.id)
        self.deps = rebuiltDeps
        self.initError = nil
        self.rootResetToken = UUID()
    }

    var availableDatasets: [DatasetDescriptor] {
        datasetCatalog.datasets
    }

    private func rebuildDependencies(resetRoot: Bool) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let previousDeps = self.deps

        do {
            let activeDatasetId = activeDatasetStore.activeDatasetId(default: datasetCatalog.defaultDataset.id)
            let dataset = datasetCatalog.dataset(id: activeDatasetId) ?? datasetCatalog.defaultDataset
            let profileId = activeDatasetStore.activeProfileId(for: dataset.id)
            self.deps = try buildDependencies(dataset: dataset, profileId: profileId)
            self.initError = nil

            if resetRoot {
                self.rootResetToken = UUID()
            }
        } catch {
            if let previousDeps {
                self.deps = previousDeps
                self.initError = nil
            } else {
                self.deps = nil
                self.initError = error.localizedDescription
            }
        }
    }

    private func buildDependencies(dataset: DatasetDescriptor, profileId: String) throws -> Dependencies {
        let databaseManager: DatabaseManaging = try DatabaseManager(
            configuration: .init(dataset: dataset, profileId: profileId)
        )

        if !UserDefaults.standard.bool(forKey: Self.inlineAICacheCleanupKey) {
            try? databaseManager.clearAIResponseCache(responseTypes: Self.staleInlineCacheResponseTypes)
            UserDefaults.standard.set(true, forKey: Self.inlineAICacheCleanupKey)
        }

        let gamificationService = GamificationService(databaseManager: databaseManager, settingsManager: settingsManager)
        let hapticService = HapticService(settingsManager: settingsManager)
        let soundService = SoundService(settingsManager: settingsManager)
        let notificationService = NotificationService(settingsManager: settingsManager)
        let assetProvider = BundleQuestionAssetProvider(dataset: dataset)

        return Dependencies(
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
            notificationService: notificationService,
            activeDataset: dataset,
            activeProfileId: profileId,
            availableDatasets: datasetCatalog.datasets,
            questionAssetProvider: assetProvider,
            switchDataset: { [weak self] datasetId in
                guard let self else { return }
                try await self.switchDataset(to: datasetId)
            }
        )
    }
}
