import Foundation
import Observation
import os

private let logger = Logger(subsystem: "com.pplaitrainer", category: "QuizViewModel")

@Observable
final class QuizViewModel {
    private let databaseManager: DatabaseManaging
    private let srsEngine: SRSEngine
    let settingsManager: SettingsManager
    let gamificationService: GamificationService
    private let hapticService: HapticService
    private let soundService: SoundService
    
    var questions: [PresentedQuestion] = []
    var currentIndex: Int = 0
    var selectedAnswer: Int? = nil
    var hasSubmitted: Bool = false
    var questionsAnswered: Int = 0
    var correctCount: Int = 0
    
    var aiMnemonic: String? = nil
    
    // Animation state
    var shakeIncorrect: Int = 0
    var showCorrectFlash: Bool = false
    var showIncorrectFlash: Bool = false
    
    // AI
    var aiConversation: AIConversationViewModel?
    
    var currentQuestion: PresentedQuestion? {
        questions.indices.contains(currentIndex) ? questions[currentIndex] : nil
    }

    var isQuizComplete: Bool {
        questionsAnswered > 0 && currentQuestion == nil
    }
    
    var questionsRemaining: Int {
        questions.count - currentIndex
    }
    
    init(databaseManager: DatabaseManaging, srsEngine: SRSEngine, aiService: AIServiceProtocol, settingsManager: SettingsManager, gamificationService: GamificationService, hapticService: HapticService, soundService: SoundService) {
        self.databaseManager = databaseManager
        self.srsEngine = srsEngine
        self.settingsManager = settingsManager
        self.gamificationService = gamificationService
        self.hapticService = hapticService
        self.soundService = soundService
        self.aiConversation = AIConversationViewModel(
            aiService: aiService,
            settingsManager: settingsManager,
            contextProvider: { [weak self] in self?.questionContextString() }
        )
    }
    
    // MARK: - Question Loading
    
    func loadQuestions(categoryId: Int64?, parentCategoryId: Int64?, wrongAnswersOnly: Bool, srsDueOnly: Bool) {
        Task { await loadQuestionsAsync(categoryId: categoryId, parentCategoryId: parentCategoryId, wrongAnswersOnly: wrongAnswersOnly, srsDueOnly: srsDueOnly) }
    }
    
    func loadQuestions(from rawQuestions: [Question]) {
        Task { @MainActor in
            do {
                questions = try rawQuestions.map { try createPresentedQuestion(from: $0) }
            } catch {
                questions = []
            }
        }
    }
    
    @MainActor
    private func loadQuestionsAsync(categoryId: Int64?, parentCategoryId: Int64?, wrongAnswersOnly: Bool, srsDueOnly: Bool) async {
        do {
            var rawQuestions: [Question] = []
            if srsDueOnly {
                let dueCards = try databaseManager.fetchDueCards(limit: nil)
                rawQuestions = try dueCards.compactMap { try databaseManager.fetchQuestion(id: $0.questionId) }
            } else if wrongAnswersOnly {
                let wrongIds = try databaseManager.fetchWrongAnswerQuestionIds()
                rawQuestions = try wrongIds.compactMap { try databaseManager.fetchQuestion(id: $0) }
            } else if let categoryId = categoryId {
                rawQuestions = try databaseManager.fetchQuestions(categoryId: categoryId, excludeMockOnly: true)
            } else if let parentCategoryId = parentCategoryId {
                rawQuestions = try databaseManager.fetchQuestions(parentCategoryId: parentCategoryId, excludeMockOnly: true)
            }
            questions = try rawQuestions.map { try createPresentedQuestion(from: $0) }
        } catch {
            questions = []
        }
    }
    
    private func createPresentedQuestion(from question: Question) throws -> PresentedQuestion {
        try PresentedQuestion.from(question, databaseManager: databaseManager)
    }
    
    // MARK: - Answer Handling
    
    func selectAnswer(_ index: Int) {
        guard !hasSubmitted else { return }
        selectedAnswer = index
    }
    
    func submitAnswer() {
        guard let selectedAnswer = selectedAnswer, let current = currentQuestion else { return }
        hasSubmitted = true
        let isCorrect = selectedAnswer == current.correctAnswerIndex
        if isCorrect { 
            correctCount += 1
            showCorrectFlash = true
        } else {
            shakeIncorrect += 1
            showIncorrectFlash = true
        }
        questionsAnswered += 1
        Task {
            await recordAnswer(questionId: current.question.id, chosenAnswer: current.shuffledAnswers[selectedAnswer], isCorrect: isCorrect)
            await updateSRSCard(questionId: current.question.id, correct: isCorrect)
            await recordStudyDay(correct: isCorrect)
            await loadStoredMnemonic(questionId: current.question.id)
            await awardXPAndCheckAchievements(questionId: current.question.id, correct: isCorrect)
        }
    }
    
    @MainActor private func awardXPAndCheckAchievements(questionId: Int64, correct: Bool) async {
        do {
            // Award XP
            _ = try gamificationService.awardXP(for: correct, isSRSCard: false)
            
            // Haptics
            if correct {
                hapticService.correctAnswer()
            } else {
                hapticService.incorrectAnswer()
            }
            
            // Streak milestone haptics
            let streak = gamificationService.consecutiveCorrectInSession
            if [3, 5, 10].contains(streak) {
                hapticService.streakMilestone(streak)
            }
            
            // Check achievements
            try gamificationService.checkAchievements(context: AchievementContext(
                lastAnsweredQuestionId: questionId,
                lastAnswerCorrect: correct
            ))
            
            // Level up feedback
            if gamificationService.didLevelUp {
                hapticService.levelUp()
            }
            
            // Badge unlock feedback
            for _ in gamificationService.recentlyUnlockedAchievements {
                hapticService.badgeUnlock()
            }
        } catch {
            // Silently fail gamification
        }
    }
    
    @MainActor private func recordAnswer(questionId: Int64, chosenAnswer: String, isCorrect: Bool) async {
        try? databaseManager.recordAnswer(AnswerRecord(id: nil, questionId: questionId, chosenAnswer: chosenAnswer, isCorrect: isCorrect, timestamp: Date()))
    }
    
    @MainActor private func updateSRSCard(questionId: Int64, correct: Bool) async {
        do {
            let card = try databaseManager.fetchOrCreateSRSCard(questionId: questionId)
            try databaseManager.updateSRSCard(srsEngine.processAnswer(card: card, correct: correct))
        } catch {}
    }
    
    @MainActor private func recordStudyDay(correct: Bool) async {
        let formatter = DateFormatter.yyyyMMdd
        try? databaseManager.recordStudyActivity(date: formatter.string(from: Date()), questionsAnswered: 1, correctAnswers: correct ? 1 : 0)
    }
    
    @MainActor private func loadStoredMnemonic(questionId: Int64) async {
        if let mnemonic = try? databaseManager.fetchMnemonic(questionId: questionId) {
            aiMnemonic = mnemonic.text
        }
    }
    
    func nextQuestion() {
        currentIndex += 1
        selectedAnswer = nil
        hasSubmitted = false
        aiMnemonic = nil
        showCorrectFlash = false
        showIncorrectFlash = false
        aiConversation?.chatMessages = []
    }
    
    func previousQuestion() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        selectedAnswer = nil
        hasSubmitted = false
        aiMnemonic = nil
        showCorrectFlash = false
        showIncorrectFlash = false
        aiConversation?.chatMessages = []
    }
    
    // MARK: - AI Chat
    
    /// Build the question context string that seeds every chat
    private func questionContextString() -> String? {
        guard let current = currentQuestion, let sel = selectedAnswer else { return nil }
        var ctx = """
        Question: \(current.question.text)
        
        Choices:
        \(current.shuffledAnswers.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))
        
        Your answer: \(current.shuffledAnswers[sel])
        Correct answer: \(current.shuffledAnswers[current.correctAnswerIndex])
        """
        if let explanation = current.question.explanation, !explanation.isEmpty {
            ctx += "\n\nOfficial explanation:\n\(explanation)"
        }
        return ctx
    }
}
