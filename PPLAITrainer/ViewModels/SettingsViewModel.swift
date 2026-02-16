import Foundation
import Observation

@Observable
final class SettingsViewModel {
    private let keychainStore: KeychainStore
    private let settingsManager: SettingsManager

    // Stored properties so @Observable can track them for SwiftUI updates
    var selectedProvider: AIProviderType {
        didSet {
            guard oldValue != selectedProvider else { return }
            // Save current key for the old provider before switching
            saveKey(for: oldValue)
            settingsManager.selectedProvider = selectedProvider.rawValue
            // Reset model to new provider's default
            let newDefault = selectedProvider.defaultModelId
            selectedModel = newDefault
            settingsManager.selectedModel = newDefault
            // Load the new provider's key
            loadCurrentKey()
        }
    }

    var selectedModel: String {
        didSet {
            settingsManager.selectedModel = selectedModel
        }
    }

    var currentApiKey: String = ""

    var aiEnabled: Bool {
        didSet { settingsManager.aiEnabled = aiEnabled }
    }

    var confirmBeforeSending: Bool {
        didSet { settingsManager.confirmBeforeSending = confirmBeforeSending }
    }

    var appearanceMode: String {
        didSet { settingsManager.appearanceMode = appearanceMode }
    }

    var systemPrompt: String {
        didSet { settingsManager.systemPrompt = systemPrompt }
    }

    var isDefaultPrompt: Bool {
        systemPrompt == SettingsManager.defaultSystemPrompt
    }

    var hasApiKey: Bool {
        !currentApiKey.isEmpty
    }

    init(keychainStore: KeychainStore, settingsManager: SettingsManager) {
        self.keychainStore = keychainStore
        self.settingsManager = settingsManager

        // Initialize stored properties from SettingsManager
        let provider = AIProviderType(rawValue: settingsManager.selectedProvider) ?? .openai
        self.selectedProvider = provider
        self.selectedModel = provider.resolveModelId(settingsManager.selectedModel)
        self.aiEnabled = settingsManager.aiEnabled
        self.confirmBeforeSending = settingsManager.confirmBeforeSending
        self.appearanceMode = settingsManager.appearanceMode
        self.systemPrompt = settingsManager.systemPrompt

        loadCurrentKey()
    }

    func loadCurrentKey() {
        currentApiKey = (try? keychainStore.read(provider: selectedProvider.rawValue)) ?? ""
    }

    func saveCurrentKey() {
        saveKey(for: selectedProvider)
    }

    private func saveKey(for provider: AIProviderType) {
        if !currentApiKey.isEmpty {
            try? keychainStore.save(key: currentApiKey, provider: provider.rawValue)
        }
    }

    func resetSystemPrompt() {
        systemPrompt = SettingsManager.defaultSystemPrompt
    }

    func resetAllKeys() {
        try? keychainStore.deleteAllKeys()
        currentApiKey = ""
    }
}
