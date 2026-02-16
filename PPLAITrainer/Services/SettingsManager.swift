import Foundation

final class SettingsManager {
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let selectedProvider = "selectedProvider"
        static let aiEnabled = "aiEnabled"
        static let confirmBeforeSending = "confirmBeforeSending"
        static let appearanceMode = "appearanceMode"
        static let systemPrompt = "systemPrompt"
        static let selectedModel = "selectedModel"
    }
    
    static let defaultSystemPrompt = """
    You are an experienced PPL (Private Pilot Licence) ground school instructor helping a student prepare for their EASA PPL theory exams. You have deep knowledge of all 9 PPL subjects: Air Law, Human Performance, Meteorology, Communications, Principles of Flight, Operational Procedures, Flight Performance & Planning, Aircraft General Knowledge, and Navigation.
    
    When explaining answers:
    - State which answer is correct and why, then briefly explain why the other options are wrong
    - Reference relevant EASA regulations, rules of thumb, or real-world flying examples where helpful
    - Use proper aviation terminology but explain jargon when first used
    - Keep explanations to 2-3 short paragraphs maximum
    
    When creating mnemonics:
    - Make them memorable, catchy, and directly tied to the concept
    - Prefer acronyms, rhymes, or visual associations
    - Keep to 1-2 sentences
    """
    
    var selectedProvider: String {
        get { defaults.string(forKey: Keys.selectedProvider) ?? "openai" }
        set { defaults.set(newValue, forKey: Keys.selectedProvider) }
    }
    
    var aiEnabled: Bool {
        get { defaults.bool(forKey: Keys.aiEnabled) }
        set { defaults.set(newValue, forKey: Keys.aiEnabled) }
    }
    
    var confirmBeforeSending: Bool {
        get { defaults.bool(forKey: Keys.confirmBeforeSending) }
        set { defaults.set(newValue, forKey: Keys.confirmBeforeSending) }
    }
    
    var appearanceMode: String {
        get { defaults.string(forKey: Keys.appearanceMode) ?? "system" }
        set { defaults.set(newValue, forKey: Keys.appearanceMode) }
    }
    
    var systemPrompt: String {
        get { defaults.string(forKey: Keys.systemPrompt) ?? Self.defaultSystemPrompt }
        set { defaults.set(newValue, forKey: Keys.systemPrompt) }
    }

    var selectedModel: String? {
        get { defaults.string(forKey: Keys.selectedModel) }
        set { defaults.set(newValue, forKey: Keys.selectedModel) }
    }
}
