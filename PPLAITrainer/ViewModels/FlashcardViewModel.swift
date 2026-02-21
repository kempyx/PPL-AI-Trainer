import Foundation
import CoreGraphics
import os

@Observable
class FlashcardViewModel {
    private let databaseManager: DatabaseManaging
    private let hapticService: HapticService
    private let aiService: AIServiceProtocol
    let settingsManager: SettingsManager
    private let logger = Logger(subsystem: "com.pplaitrainer", category: "FlashcardViewModel")
    
    var questions: [Question] = []
    var currentIndex = 0
    var isRevealed = false
    var reviewPile: [Question] = []
    var knownCount = 0
    var round = 1
    var showRoundSummary = false
    var sessionComplete = false
    var totalRevealed = 0
    var totalCorrect = 0
    var reverseMode = false // Question on back, answer on front
    
    // Swipe state
    var dragOffset: CGSize = .zero
    var hitThreshold = false
    
    // AI
    var aiConversation: AIConversationViewModel?
    
    var currentQuestion: Question? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    
    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentIndex) / Double(questions.count)
    }
    
    var shuffledChoices: [String] {
        guard let q = currentQuestion else { return [] }
        return [q.correct, q.incorrect0, q.incorrect1, q.incorrect2].shuffled()
    }
    
    private var cachedChoices: [Int64: [String]] = [:]
    
    func choicesForCurrent() -> [String] {
        guard let q = currentQuestion else { return [] }
        if let cached = cachedChoices[q.id] { return cached }
        let choices = [q.correct, q.incorrect0, q.incorrect1, q.incorrect2].shuffled()
        cachedChoices[q.id] = choices
        return choices
    }
    
    init(databaseManager: DatabaseManaging, hapticService: HapticService, aiService: AIServiceProtocol, settingsManager: SettingsManager) {
        self.databaseManager = databaseManager
        self.hapticService = hapticService
        self.aiService = aiService
        self.settingsManager = settingsManager
        self.aiConversation = AIConversationViewModel(
            aiService: aiService,
            settingsManager: settingsManager,
            contextProvider: { [weak self] in self?.questionContextString() }
        )
    }
    
    func loadQuestions(sessionType: SessionType, leg: ExamLeg) {
        do {
            let engine = SmartSessionEngine(databaseManager: databaseManager)
            questions = try engine.generateSession(type: sessionType, leg: leg)
            resetRound()
        } catch {
            logger.error("Failed to load flashcards: \(error)")
        }
    }
    
    func swipeRight() {
        guard let q = currentQuestion else { return }
        knownCount += 1
        if isRevealed {
            recordResult(question: q, correct: true)
        }
        hapticService.correctAnswer()
        advance()
    }
    
    func swipeLeft() {
        guard let q = currentQuestion else { return }
        reviewPile.append(q)
        if isRevealed {
            recordResult(question: q, correct: false)
        }
        hapticService.incorrectAnswer()
        advance()
    }
    
    func reveal() {
        isRevealed = true
        hapticService.streakMilestone(1) // light impact
    }
    
    func startNextRound() {
        round += 1
        questions = reviewPile.shuffled()
        reviewPile = []
        knownCount = 0
        resetRound()
        showRoundSummary = false
    }
    
    func finishSession() {
        sessionComplete = true
        showRoundSummary = false
    }
    
    // MARK: - Private
    
    private func advance() {
        isRevealed = false
        cachedChoices.removeValue(forKey: currentQuestion?.id ?? 0)
        aiConversation?.chatMessages = []
        currentIndex += 1
        if currentIndex >= questions.count {
            showRoundSummary = true
        }
    }
    
    private func resetRound() {
        currentIndex = 0
        isRevealed = false
        cachedChoices = [:]
    }
    
    private func recordResult(question: Question, correct: Bool) {
        totalRevealed += 1
        if correct { totalCorrect += 1 }
        do {
            let record = AnswerRecord(
                questionId: question.id,
                chosenAnswer: correct ? question.correct : "",
                isCorrect: correct,
                timestamp: Date()
            )
            try databaseManager.recordAnswer(record)
            
            var srsCard = try databaseManager.fetchOrCreateSRSCard(questionId: question.id)
            let srs = SRSEngine()
            srsCard = srs.processAnswer(card: srsCard, correct: correct)
            try databaseManager.updateSRSCard(srsCard)
            
            let formatter = DateFormatter.yyyyMMdd
            try databaseManager.recordStudyActivity(
                date: formatter.string(from: Date()),
                questionsAnswered: 1,
                correctAnswers: correct ? 1 : 0
            )
        } catch {
            logger.error("Failed to record flashcard result: \(error)")
        }
    }
    
    private func questionContextString() -> String? {
        guard let q = currentQuestion else { return nil }
        let choices = choicesForCurrent()
        var ctx = """
        Question: \(q.text)
        
        Choices:
        \(choices.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))
        
        Correct answer: \(q.correct)
        """
        if let explanation = q.explanation, !explanation.isEmpty {
            ctx += "\n\nOfficial explanation:\n\(explanation)"
        }
        return ctx
    }
}
