import Foundation
import Observation
import os

private let logger = Logger(subsystem: "com.primendro.PPLAITrainer", category: "Bootstrap")

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
    private let datasets: [DatasetDescriptor]
    private let datasetsById: [String: DatasetDescriptor]
    private let defaultDataset: DatasetDescriptor

    private static let legacyDatabaseFilename = "153-en.sqlite"
    private static let legacyDatabaseResourceName = "153-en"
    private static let legacyDatabaseExtension = "sqlite"

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
        self.datasets = self.datasetCatalog.datasets
        self.datasetsById = Dictionary(uniqueKeysWithValues: self.datasetCatalog.datasets.map { ($0.id, $0) })
        self.defaultDataset = self.datasetCatalog.defaultDataset

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
        let requestedId = String(datasetId)

        guard let dataset = datasetsById[requestedId] else {
            logger.error("Dataset switch rejected. Unknown dataset id: \(requestedId, privacy: .public)")
            throw NSError(domain: "AppBootstrapper", code: 1, userInfo: [NSLocalizedDescriptionKey: "Dataset not found: \(requestedId)"])
        }

        guard !isLoading else {
            throw NSError(domain: "AppBootstrapper", code: 2, userInfo: [NSLocalizedDescriptionKey: "Dataset switch already in progress"])
        }

        logger.info("Switching dataset to \(requestedId, privacy: .public)")
        let profileId = activeDatasetStore.activeProfileId(for: dataset.id)

        isLoading = true
        defer { isLoading = false }

        let rebuiltDeps: Dependencies
        do {
            rebuiltDeps = try buildDependencies(dataset: dataset, profileId: profileId)
        } catch {
            logger.error("Dataset switch build failed for \(requestedId, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw NSError(domain: "AppBootstrapper", code: 3, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
        }

        activeDatasetStore.setActiveDatasetId(dataset.id)
        self.deps = rebuiltDeps
        self.initError = nil
        self.rootResetToken = UUID()
        logger.info("Dataset switch committed for \(requestedId, privacy: .public)")
    }

    var availableDatasets: [DatasetDescriptor] {
        datasets
    }

    private func rebuildDependencies(resetRoot: Bool) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let previousDeps = self.deps

        do {
            let dataset = resolveBootstrapDataset()
            let profileId = activeDatasetStore.activeProfileId(for: dataset.id)
            self.deps = try buildDependencies(dataset: dataset, profileId: profileId)
            if settingsManager.activeDatasetId == nil {
                activeDatasetStore.setActiveDatasetId(dataset.id)
            }
            self.initError = nil

            if resetRoot {
                self.rootResetToken = UUID()
            }
        } catch {
            logger.error("Bootstrap dependency rebuild failed: \(error.localizedDescription, privacy: .public)")
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
            availableDatasets: datasets,
            questionAssetProvider: assetProvider,
            switchDataset: { [weak self] datasetId in
                guard let self else { return }
                try await self.switchDataset(to: datasetId)
            }
        )
    }

    private func resolveBootstrapDataset() -> DatasetDescriptor {
        if let storedId = settingsManager.activeDatasetId,
           let storedDataset = datasetsById[storedId] {
            return storedDataset
        }

        if settingsManager.activeDatasetId == nil,
           hasLegacyDatabaseInDocuments(),
           let legacyDataset = datasets.first(where: {
               $0.databaseResourceName == Self.legacyDatabaseResourceName &&
               $0.databaseExtension == Self.legacyDatabaseExtension
           }) {
            return legacyDataset
        }

        return defaultDataset
    }

    private func hasLegacyDatabaseInDocuments(fileManager: FileManager = .default) -> Bool {
        guard let documents = try? fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) else {
            return false
        }

        let legacyPath = documents.appendingPathComponent(Self.legacyDatabaseFilename)
        return fileManager.fileExists(atPath: legacyPath.path)
    }
}
