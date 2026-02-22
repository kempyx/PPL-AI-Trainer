import Foundation

protocol ActiveDatasetStoring {
    func activeDatasetId(default fallbackId: String) -> String
    func setActiveDatasetId(_ id: String)
    func activeProfileId(for datasetId: String) -> String
    func setActiveProfileId(_ profileId: String, for datasetId: String)
}

final class ActiveDatasetStore: ActiveDatasetStoring {
    private let settingsManager: SettingsManager

    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }

    func activeDatasetId(default fallbackId: String) -> String {
        settingsManager.activeDatasetId ?? fallbackId
    }

    func setActiveDatasetId(_ id: String) {
        settingsManager.activeDatasetId = id
    }

    func activeProfileId(for datasetId: String) -> String {
        settingsManager.profileId(for: datasetId)
    }

    func setActiveProfileId(_ profileId: String, for datasetId: String) {
        settingsManager.setProfileId(profileId, for: datasetId)
    }
}
