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
    private(set) var settingsManager: SettingsManager

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
            AIPromptItem(key: .hintRequest, title: "Question Hint", description: "Prompt template for generating hints.", tokenHints: ["{{question}}", "{{choiceA}}", "{{choiceB}}", "{{choiceC}}", "{{choiceD}}", "{{correctAnswer}}"]),
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

    init(keychainStore: KeychainStore, settingsManager: SettingsManager) {
        self.keychainStore = keychainStore
        self.settingsManager = settingsManager

        // Initialize stored properties from SettingsManager
        let provider = AIProviderType(rawValue: settingsManager.selectedProvider) ?? .openai
        self.selectedProvider = provider
        self.selectedModel = provider.resolveModelId(settingsManager.selectedModel)
        self.aiEnabled = settingsManager.aiEnabled
        self.confirmBeforeSending = settingsManager.confirmBeforeSending
        self.showPremiumContent = settingsManager.showPremiumContent
        self.appearanceMode = settingsManager.appearanceMode
        self.systemPrompt = settingsManager.systemPrompt
        self.aiPrompts = Dictionary(uniqueKeysWithValues: SettingsManager.AIPromptKey.allCases.map { ($0, settingsManager.prompt(for: $0)) })
        self.activeLeg = settingsManager.activeLeg
        self.examDateLeg1 = settingsManager.examDateLeg1
        self.examDateLeg2 = settingsManager.examDateLeg2
        self.examDateLeg3 = settingsManager.examDateLeg3

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
}
