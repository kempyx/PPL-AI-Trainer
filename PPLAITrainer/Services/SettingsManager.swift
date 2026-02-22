import Foundation

final class SettingsManager {
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let selectedProvider = "selectedProvider"
        static let aiEnabled = "aiEnabled"
        static let hintImageCount = "hintImageCount"
        static let confirmBeforeSending = "confirmBeforeSending"
        static let showPremiumContent = "showPremiumContent"
        static let activeDatasetId = "activeDatasetId"
        static let profileIdsByDataset = "profileIdsByDataset"
        static let appearanceMode = "appearanceMode"
        static let systemPrompt = "systemPrompt"
        static let aiPromptOverrides = "aiPromptOverrides"
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
        static let installationId = "installationId"
        static let experimentOverrides = "experimentOverrides"
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
    - For mathematical formulas, prefer LaTeX math notation with delimiters:
      • Inline math: $V = d/t$ or \\(V = d/t\\)
      • Display math: $$L = \\frac{1}{2}\\rho V^2 S C_L$$ or \\[L = \\frac{1}{2}\\rho V^2 S C_L\\]
      • Keep formulas readable and include variable meaning when helpful
      • Unicode symbols are fine too (for example ρ, α, β, ±)
    - State the correct answer and why in one sentence
    - Briefly note why their answer was wrong (if applicable)
    - Only elaborate if they ask follow-up questions
    """

    enum AIPromptKey: String, CaseIterable, Identifiable {
        case system
        case quickActionExplain
        case quickActionSimplify
        case quickActionAnalogy
        case quickActionMistakes
        case hintRequest
        case deepHintRequest
        case inlineExplain
        case inlineSimplify
        case inlineAnalogy
        case inlineMistakes
        case contextualExplain
        case visualGeneration

        var id: String { rawValue }
    }

    static let defaultAIPrompts: [AIPromptKey: String] = [
        .system: defaultSystemPrompt,
        .quickActionExplain: "Explain why the correct answer is right.",
        .quickActionSimplify: "Simplify this concept. Break it down into simple terms.",
        .quickActionAnalogy: "Give me a real-world analogy to help me understand this concept.",
        .quickActionMistakes: "What do students commonly get wrong about this? What should I watch out for?",
        .hintRequest: """
        You are a flight instructor helping a student solve a PPL theory question.
        Give a concise text-only hint that guides the student toward the right reasoning without revealing the answer directly.

        Question: {{question}}

        Choices:
        A. {{choiceA}}
        B. {{choiceB}}
        C. {{choiceC}}
        D. {{choiceD}}

        Correct answer text (never reveal directly): {{correctAnswer}}

        Requirements:
        - Text only, no images.
        - Max 3 short sentences.
        - Do not reference answer letters (A/B/C/D); refer only to concept wording.
        - Do not state the correct answer text verbatim.
        """,
        .deepHintRequest: """
        You are a flight instructor helping a student solve a PPL theory question.
        Provide a deeper multimodal hint with concise text plus visual support.

        Question: {{question}}

        Choices:
        A. {{choiceA}}
        B. {{choiceB}}
        C. {{choiceC}}
        D. {{choiceD}}

        Correct answer text (never reveal directly): {{correctAnswer}}
        Question image context: {{questionImageContext}}
        Requested image count: {{imageCount}}

        Requirements:
        - Text hint: max 4 short sentences, more detailed than a normal hint.
        - Generate up to {{imageCount}} simple educational diagram image(s) that help reasoning.
        - Keep visuals schematic and instructional: clear labels, arrows, short callouts, high contrast, minimal clutter.
        - Do not reference answer letters (A/B/C/D); refer only to concept wording.
        - Do not state the correct answer text verbatim.
        """,
        .inlineExplain: "Explain this concept in more detail, focusing on the aviation principles involved.\n\n{{context}}",
        .inlineSimplify: "Simplify this explanation using plain language that a beginner pilot can understand.\n\n{{context}}",
        .inlineAnalogy: "Provide a helpful analogy or real-world example to illustrate this concept.\n\n{{context}}",
        .inlineMistakes: "Explain the most common mistakes students make with this question and how to avoid them.\n\n{{context}}",
        .contextualExplain: """
        Explain this selected aviation term from the question in a concise, exam-focused way.

        Selected text: "{{selectedText}}"
        Question: {{question}}
        Correct answer: {{correctAnswer}}
        {{officialExplanation}}
        """,
        .visualGeneration: """
        Create a clear, high-contrast, non-photorealistic instructional aviation diagram for student pilots that teaches this concept: {{question}}. Use a clean schematic layout with minimal clutter, clear labels, directional arrows, and short callouts; make the correct answer explicit in the visual: {{correctAnswer}}; represent this official explanation visually: {{officialExplanation}}; and include essential aviation domain knowledge needed for technical accuracy and exam understanding.
        """
    ]
    
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

    var hintImageCount: Int {
        get {
            let stored = defaults.integer(forKey: Keys.hintImageCount)
            if stored == 0 { return 1 }
            return max(1, min(3, stored))
        }
        set {
            defaults.set(max(1, min(3, newValue)), forKey: Keys.hintImageCount)
        }
    }
    
    var confirmBeforeSending: Bool {
        get { defaults.bool(forKey: Keys.confirmBeforeSending) }
        set { defaults.set(newValue, forKey: Keys.confirmBeforeSending) }
    }

    var showPremiumContent: Bool {
        get { defaults.bool(forKey: Keys.showPremiumContent) }
        set {
            defaults.set(newValue, forKey: Keys.showPremiumContent)
            notifyChange()
        }
    }
    
    var appearanceMode: String {
        get { defaults.string(forKey: Keys.appearanceMode) ?? "system" }
        set { defaults.set(newValue, forKey: Keys.appearanceMode) }
    }

    var activeDatasetId: String? {
        get { defaults.string(forKey: Keys.activeDatasetId) }
        set {
            defaults.set(newValue, forKey: Keys.activeDatasetId)
            notifyChange()
        }
    }

    func profileId(for datasetId: String) -> String {
        if let profile = profileIdsByDataset[datasetId], !profile.isEmpty {
            return profile
        }
        return datasetId
    }

    func setProfileId(_ profileId: String, for datasetId: String) {
        var profiles = profileIdsByDataset
        profiles[datasetId] = profileId
        defaults.set(profiles, forKey: Keys.profileIdsByDataset)
    }
    
    var systemPrompt: String {
        get { prompt(for: .system) }
        set { setPrompt(newValue, for: .system) }
    }

    func prompt(for key: AIPromptKey) -> String {
        if key == .system,
           let legacyPrompt = defaults.string(forKey: Keys.systemPrompt),
           promptOverrides[key.rawValue] == nil {
            return legacyPrompt
        }
        return promptOverrides[key.rawValue] ?? Self.defaultAIPrompts[key] ?? ""
    }

    func setPrompt(_ prompt: String, for key: AIPromptKey) {
        if key == .system {
            defaults.set(prompt, forKey: Keys.systemPrompt)
        }
        var overrides = promptOverrides
        let defaultValue = Self.defaultAIPrompts[key] ?? ""
        if prompt == defaultValue {
            overrides.removeValue(forKey: key.rawValue)
        } else {
            overrides[key.rawValue] = prompt
        }
        defaults.set(overrides, forKey: Keys.aiPromptOverrides)
    }

    func resetPrompt(_ key: AIPromptKey) {
        setPrompt(Self.defaultAIPrompts[key] ?? "", for: key)
    }

    func renderPrompt(_ key: AIPromptKey, values: [String: String]) -> String {
        var rendered = prompt(for: key)
        for (token, value) in values {
            rendered = rendered.replacingOccurrences(of: "{{\(token)}}", with: value)
        }
        return rendered
    }

    private var promptOverrides: [String: String] {
        defaults.dictionary(forKey: Keys.aiPromptOverrides) as? [String: String] ?? [:]
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

    // MARK: - Experiments

    func experimentVariant(for experiment: AppExperiment) -> String {
        if let override = experimentOverride(for: experiment),
           experiment.variants.contains(override) {
            return override
        }
        let variants = experiment.variants
        guard !variants.isEmpty else { return "control" }
        let seed = "\(installationId):\(experiment.rawValue)"
        let idx = Int(stableHash(seed) % UInt64(variants.count))
        return variants[idx]
    }

    func experimentOverride(for experiment: AppExperiment) -> String? {
        guard let overrides = defaults.dictionary(forKey: Keys.experimentOverrides) as? [String: String] else {
            return nil
        }
        return overrides[experiment.rawValue]
    }

    func setExperimentOverride(_ variant: String?, for experiment: AppExperiment) {
        var overrides = (defaults.dictionary(forKey: Keys.experimentOverrides) as? [String: String]) ?? [:]
        if let variant, !variant.isEmpty {
            overrides[experiment.rawValue] = variant
        } else {
            overrides.removeValue(forKey: experiment.rawValue)
        }
        defaults.set(overrides, forKey: Keys.experimentOverrides)
    }

    func clearExperimentOverrides() {
        defaults.removeObject(forKey: Keys.experimentOverrides)
    }

    func experimentAssignments() -> [ExperimentAssignment] {
        AppExperiment.allCases.map { experiment in
            ExperimentAssignment(
                experiment: experiment,
                override: experimentOverride(for: experiment),
                resolved: experimentVariant(for: experiment)
            )
        }
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

    private var installationId: String {
        if let existing = defaults.string(forKey: Keys.installationId), !existing.isEmpty {
            return existing
        }
        let newValue = UUID().uuidString
        defaults.set(newValue, forKey: Keys.installationId)
        return newValue
    }

    private func stableHash(_ input: String) -> UInt64 {
        input.utf8.reduce(5381) { (hash, char) in
            ((hash << 5) &+ hash) &+ UInt64(char)
        }
    }

    private var profileIdsByDataset: [String: String] {
        defaults.dictionary(forKey: Keys.profileIdsByDataset) as? [String: String] ?? [:]
    }
}
