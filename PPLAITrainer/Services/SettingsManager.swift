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
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let examDateLeg1 = "examDateLeg1"
        static let examDateLeg2 = "examDateLeg2"
        static let examDateLeg3 = "examDateLeg3"
        static let dailyGoalTarget = "dailyGoalTarget"
        static let notificationsEnabled = "notificationsEnabled"
        static let reminderTime = "reminderTime"
        static let streakReminderEnabled = "streakReminderEnabled"
        static let hapticFeedbackEnabled = "hapticFeedbackEnabled"
        static let soundEnabled = "soundEnabled"
        static let activeLeg = "activeLeg"
        static let lastStudiedSubjectId = "lastStudiedSubjectId"
        static let lastStudiedSubjectName = "lastStudiedSubjectName"
    }
    
    static let defaultSystemPrompt = """
    You are a PPL ground school instructor helping a student prepare for EASA PPL theory exams.
    
    Rules:
    - Address the student directly using "you" and "your"
    - Be concise: max 3-4 sentences per response
    - Use full Markdown formatting:
      • **bold** for emphasis
      • *italic* for terms
      • `code` for technical values
      • - or • for bullet lists
      • ### for section headers (if needed)
      • > for important notes/quotes
    - For mathematical formulas, use Unicode symbols (NOT LaTeX):
      • Use ½ instead of \\frac{1}{2}
      • Use ρ, α, β for Greek letters
      • Use ² ³ for superscripts (V² not V^2)
      • Use × ÷ ± for operators
      • Example: "Q = ½ρV²" not "$Q = \\frac{1}{2} \\rho V^2$"
    - State the correct answer and why in one sentence
    - Briefly note why their answer was wrong (if applicable)
    - Only elaborate if they ask follow-up questions
    """
    
    private func notifyChange() {
        NotificationCenter.default.post(name: .settingsDidChange, object: nil)
    }
    
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
    
    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }
    
    var examDateLeg1: Date? {
        get { defaults.object(forKey: Keys.examDateLeg1) as? Date }
        set { 
            defaults.set(newValue, forKey: Keys.examDateLeg1)
            notifyChange()
        }
    }
    
    var examDateLeg2: Date? {
        get { defaults.object(forKey: Keys.examDateLeg2) as? Date }
        set { 
            defaults.set(newValue, forKey: Keys.examDateLeg2)
            notifyChange()
        }
    }
    
    var examDateLeg3: Date? {
        get { defaults.object(forKey: Keys.examDateLeg3) as? Date }
        set { 
            defaults.set(newValue, forKey: Keys.examDateLeg3)
            notifyChange()
        }
    }
    
    var nearestExamDate: Date? {
        [examDateLeg1, examDateLeg2, examDateLeg3]
            .compactMap { $0 }
            .filter { $0 > Date() }
            .min()
    }
    
    var dailyGoalTarget: Int {
        get {
            let val = defaults.integer(forKey: Keys.dailyGoalTarget)
            return val > 0 ? val : 20
        }
        set { defaults.set(newValue, forKey: Keys.dailyGoalTarget) }
    }
    
    var notificationsEnabled: Bool {
        get { defaults.bool(forKey: Keys.notificationsEnabled) }
        set { 
            defaults.set(newValue, forKey: Keys.notificationsEnabled)
            notifyChange()
        }
    }
    
    var reminderTime: Date {
        get {
            if let date = defaults.object(forKey: Keys.reminderTime) as? Date { return date }
            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = 20
            components.minute = 0
            return Calendar.current.date(from: components) ?? Date()
        }
        set { 
            defaults.set(newValue, forKey: Keys.reminderTime)
            notifyChange()
        }
    }
    
    var streakReminderEnabled: Bool {
        get { defaults.bool(forKey: Keys.streakReminderEnabled) }
        set { 
            defaults.set(newValue, forKey: Keys.streakReminderEnabled)
            notifyChange()
        }
    }
    
    var hapticFeedbackEnabled: Bool {
        get {
            if defaults.object(forKey: Keys.hapticFeedbackEnabled) == nil { return true }
            return defaults.bool(forKey: Keys.hapticFeedbackEnabled)
        }
        set { defaults.set(newValue, forKey: Keys.hapticFeedbackEnabled) }
    }
    
    var soundEnabled: Bool {
        get {
            if defaults.object(forKey: Keys.soundEnabled) == nil { return true }
            return defaults.bool(forKey: Keys.soundEnabled)
        }
        set { defaults.set(newValue, forKey: Keys.soundEnabled) }
    }
    
    var activeLeg: ExamLeg {
        get { ExamLeg(rawValue: defaults.integer(forKey: Keys.activeLeg)) ?? .technicalLegal }
        set { defaults.set(newValue.rawValue, forKey: Keys.activeLeg) }
    }
    
    var lastStudiedSubjectId: Int64? {
        get {
            let val = defaults.object(forKey: Keys.lastStudiedSubjectId) as? Int64
            return val == 0 ? nil : val
        }
        set { defaults.set(newValue, forKey: Keys.lastStudiedSubjectId) }
    }
    
    var lastStudiedSubjectName: String? {
        get { defaults.string(forKey: Keys.lastStudiedSubjectName) }
        set { defaults.set(newValue, forKey: Keys.lastStudiedSubjectName) }
    }
    
    func setLastStudiedSubject(id: Int64, name: String) {
        lastStudiedSubjectId = id
        lastStudiedSubjectName = name
    }
    
    func resetUserProgress() {
        let keysToReset = [
            Keys.hasCompletedOnboarding, Keys.examDateLeg1, Keys.examDateLeg2, Keys.examDateLeg3, Keys.dailyGoalTarget,
            Keys.notificationsEnabled, Keys.reminderTime, Keys.streakReminderEnabled,
            Keys.hapticFeedbackEnabled, Keys.soundEnabled, Keys.activeLeg,
            Keys.lastStudiedSubjectId, Keys.lastStudiedSubjectName
        ]
        for key in keysToReset {
            defaults.removeObject(forKey: key)
        }
    }
}
