import Foundation
import Observation

@Observable
final class SettingsViewModel {
    struct AIPromptItem: Identifiable {
        let key: SettingsManager.AIPromptKey
        let title: String
        let description: String
        let tokenHints: [String]

        var id: String { key.rawValue }
    }

    private let keychainStore: KeychainStore
    private let switchDatasetAction: ((String) async throws -> Void)?
    private(set) var settingsManager: SettingsManager
    let availableDatasets: [DatasetDescriptor]

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

    var hintImageCount: Int {
        didSet { settingsManager.hintImageCount = max(1, min(3, hintImageCount)) }
    }

    var confirmBeforeSending: Bool {
        didSet { settingsManager.confirmBeforeSending = confirmBeforeSending }
    }

    var showPremiumContent: Bool {
        didSet { settingsManager.showPremiumContent = showPremiumContent }
    }

    var appearanceMode: String {
        didSet { settingsManager.appearanceMode = appearanceMode }
    }

    var systemPrompt: String {
        didSet { settingsManager.systemPrompt = systemPrompt }
    }

    var aiPrompts: [SettingsManager.AIPromptKey: String]
    
    var activeLeg: ExamLeg {
        didSet { settingsManager.activeLeg = activeLeg }
    }

    var activeDatasetId: String

    var activeProfileId: String

    var isSwitchingDataset = false

    var datasetSwitchErrorMessage: String?
    
    var examDateLeg1: Date? {
        didSet { settingsManager.examDateLeg1 = examDateLeg1 }
    }
    
    var examDateLeg2: Date? {
        didSet { settingsManager.examDateLeg2 = examDateLeg2 }
    }
    
    var examDateLeg3: Date? {
        didSet { settingsManager.examDateLeg3 = examDateLeg3 }
    }

    var isDefaultPrompt: Bool {
        systemPrompt == SettingsManager.defaultSystemPrompt
    }

    var promptItems: [AIPromptItem] {
        [
            AIPromptItem(key: .system, title: "System Prompt", description: "Global instructions shared by all AI providers.", tokenHints: []),
            AIPromptItem(key: .quickActionExplain, title: "Quick Action: Explain", description: "User message used by the one-tap Explain action.", tokenHints: []),
            AIPromptItem(key: .quickActionSimplify, title: "Quick Action: Simplify", description: "User message used by the one-tap Simplify action.", tokenHints: []),
            AIPromptItem(key: .quickActionAnalogy, title: "Quick Action: Analogy", description: "User message used by the one-tap Analogy action.", tokenHints: []),
            AIPromptItem(key: .quickActionMistakes, title: "Quick Action: Mistakes", description: "User message used by the one-tap Mistakes action.", tokenHints: []),
            AIPromptItem(key: .hintRequest, title: "Question Hint", description: "Prompt template for generating hints.", tokenHints: ["{{question}}", "{{choiceA}}", "{{choiceB}}", "{{choiceC}}", "{{choiceD}}", "{{correctAnswer}}", "{{questionImageContext}}", "{{visualRequested}}", "{{imageCount}}"]),
            AIPromptItem(key: .inlineExplain, title: "Inline Explain", description: "Prompt template for inline explain requests.", tokenHints: ["{{context}}"]),
            AIPromptItem(key: .inlineSimplify, title: "Inline Simplify", description: "Prompt template for inline simplify requests.", tokenHints: ["{{context}}"]),
            AIPromptItem(key: .inlineAnalogy, title: "Inline Analogy", description: "Prompt template for inline analogy requests.", tokenHints: ["{{context}}"]),
            AIPromptItem(key: .inlineMistakes, title: "Inline Mistakes", description: "Prompt template for inline mistakes requests.", tokenHints: ["{{context}}"]),
            AIPromptItem(key: .contextualExplain, title: "Contextual Explain", description: "Prompt template when explaining highlighted text.", tokenHints: ["{{selectedText}}", "{{question}}", "{{correctAnswer}}", "{{officialExplanation}}"]),
            AIPromptItem(key: .visualGeneration, title: "Visual Prompt Generator", description: "Template used to generate copy-paste prompts for educational diagram images.", tokenHints: ["{{question}}", "{{correctAnswer}}", "{{officialExplanation}}"])
        ]
    }

    var modifiedPromptCount: Int {
        promptItems.filter { promptText(for: $0.key) != (SettingsManager.defaultAIPrompts[$0.key] ?? "") }.count
    }

    var hasApiKey: Bool {
        !currentApiKey.isEmpty
    }

    var activeDatasetDisplayName: String {
        datasetDescriptor(for: activeDatasetId)?.displayName ?? activeDatasetId
    }
    
    var suggestedLeg: ExamLeg? {
        let dates: [(ExamLeg, Date)] = [
            (.technicalLegal, examDateLeg1),
            (.humanEnvironment, examDateLeg2),
            (.planningNavigation, examDateLeg3)
        ].compactMap { leg, date in
            guard let date, date > Date() else { return nil }
            return (leg, date)
        }
        
        guard let nearest = dates.min(by: { $0.1 < $1.1 }) else { return nil }
        return nearest.0 != activeLeg ? nearest.0 : nil
    }

    init(
        keychainStore: KeychainStore,
        settingsManager: SettingsManager,
        availableDatasets: [DatasetDescriptor] = [],
        activeDatasetId: String? = nil,
        activeProfileId: String? = nil,
        switchDataset: ((String) async throws -> Void)? = nil
    ) {
        self.keychainStore = keychainStore
        self.settingsManager = settingsManager
        self.availableDatasets = availableDatasets
        self.switchDatasetAction = switchDataset

        // Initialize stored properties from SettingsManager
        let resolvedDatasetId = activeDatasetId
            ?? settingsManager.activeDatasetId
            ?? availableDatasets.first?.id
            ?? "easa.en.v153"
        self.activeDatasetId = resolvedDatasetId
        self.activeProfileId = activeProfileId ?? settingsManager.profileId(for: resolvedDatasetId)
        let provider = AIProviderType(rawValue: settingsManager.selectedProvider) ?? .openai
        self.selectedProvider = provider
        self.selectedModel = provider.resolveModelId(settingsManager.selectedModel)
        self.aiEnabled = settingsManager.aiEnabled
        self.hintImageCount = settingsManager.hintImageCount
        self.confirmBeforeSending = settingsManager.confirmBeforeSending
        self.showPremiumContent = settingsManager.showPremiumContent
        self.appearanceMode = settingsManager.appearanceMode
        self.systemPrompt = settingsManager.systemPrompt
        self.aiPrompts = Dictionary(uniqueKeysWithValues: SettingsManager.AIPromptKey.allCases.map { ($0, settingsManager.prompt(for: $0)) })
        self.activeLeg = settingsManager.activeLeg
        self.examDateLeg1 = settingsManager.examDateLeg1
        self.examDateLeg2 = settingsManager.examDateLeg2
        self.examDateLeg3 = settingsManager.examDateLeg3
        self.datasetSwitchErrorMessage = nil

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

    func promptText(for key: SettingsManager.AIPromptKey) -> String {
        aiPrompts[key] ?? SettingsManager.defaultAIPrompts[key] ?? ""
    }

    func updatePrompt(_ key: SettingsManager.AIPromptKey, text: String) {
        aiPrompts[key] = text
        settingsManager.setPrompt(text, for: key)
        if key == .system {
            systemPrompt = text
        }
    }

    func resetPrompt(_ key: SettingsManager.AIPromptKey) {
        let defaultText = SettingsManager.defaultAIPrompts[key] ?? ""
        updatePrompt(key, text: defaultText)
    }

    func resetAllKeys() {
        try? keychainStore.deleteAllKeys()
        currentApiKey = ""
    }
    
    func acceptSuggestedLeg() {
        if let suggested = suggestedLeg {
            activeLeg = suggested
        }
    }

    func datasetDescriptor(for id: String) -> DatasetDescriptor? {
        availableDatasets.first(where: { $0.id == id })
    }

    @MainActor
    func switchDatasetIfNeeded(to datasetId: String) async {
        guard datasetId != activeDatasetId else { return }
        guard let switchDatasetAction else { return }

        isSwitchingDataset = true
        datasetSwitchErrorMessage = nil
        defer { isSwitchingDataset = false }

        do {
            try await switchDatasetAction(datasetId)
            activeDatasetId = datasetId
            activeProfileId = settingsManager.profileId(for: datasetId)
        } catch {
            datasetSwitchErrorMessage = error.localizedDescription
        }
    }

    func clearDatasetSwitchError() {
        datasetSwitchErrorMessage = nil
    }
}
