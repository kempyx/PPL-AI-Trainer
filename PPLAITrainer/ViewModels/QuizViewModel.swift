import Foundation
import Observation
import os

private let logger = Logger(subsystem: "com.pplaitrainer", category: "QuizViewModel")

@Observable
final class QuizViewModel {
    private let databaseManager: DatabaseManaging
    private let srsEngine: SRSEngine
    private let aiService: AIServiceProtocol
    let settingsManager: SettingsManager
    
    var questions: [PresentedQuestion] = []
    var currentIndex: Int = 0
    var selectedAnswer: Int? = nil
    var hasSubmitted: Bool = false
    var questionsAnswered: Int = 0
    var correctCount: Int = 0
    
    var aiMnemonic: String? = nil
    var isLoadingAI: Bool = false
    var aiError: AIServiceError? = nil
    var showConfirmation: Bool = false
    var pendingAIRequest: (() -> Void)? = nil
    var showAISheet: Bool = false
    
    // Chat state
    var chatMessages: [ChatMessage] = []
    var displayedAIText: String = ""
    private var typewriterTask: Task<Void, Never>?
    
    var currentQuestion: PresentedQuestion? {
        questions.indices.contains(currentIndex) ? questions[currentIndex] : nil
    }

    var isQuizComplete: Bool {
        questionsAnswered > 0 && currentQuestion == nil
    }
    
    var questionsRemaining: Int {
        questions.count - currentIndex
    }
    
    init(databaseManager: DatabaseManaging, srsEngine: SRSEngine, aiService: AIServiceProtocol, settingsManager: SettingsManager) {
        self.databaseManager = databaseManager
        self.srsEngine = srsEngine
        self.aiService = aiService
        self.settingsManager = settingsManager
    }
    
    // MARK: - Question Loading
    
    func loadQuestions(categoryId: Int64?, parentCategoryId: Int64?, wrongAnswersOnly: Bool, srsDueOnly: Bool) {
        Task { await loadQuestionsAsync(categoryId: categoryId, parentCategoryId: parentCategoryId, wrongAnswersOnly: wrongAnswersOnly, srsDueOnly: srsDueOnly) }
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
        if isCorrect { correctCount += 1 }
        questionsAnswered += 1
        Task {
            await recordAnswer(questionId: current.question.id, chosenAnswer: current.shuffledAnswers[selectedAnswer], isCorrect: isCorrect)
            await updateSRSCard(questionId: current.question.id, correct: isCorrect)
            await recordStudyDay(correct: isCorrect)
            await loadStoredMnemonic(questionId: current.question.id)
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
        typewriterTask?.cancel()
        currentIndex += 1
        selectedAnswer = nil
        hasSubmitted = false
        aiMnemonic = nil
        aiError = nil
        chatMessages = []
        displayedAIText = ""
        showAISheet = false
    }
    
    // MARK: - AI Chat
    
    /// Build the question context string that seeds every chat
    private func questionContextString() -> String? {
        guard let current = currentQuestion, let sel = selectedAnswer else { return nil }
        var ctx = """
        Question: \(current.question.text)
        
        Choices:
        \(current.shuffledAnswers.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))
        
        Student's answer: \(current.shuffledAnswers[sel])
        Correct answer: \(current.shuffledAnswers[current.correctAnswerIndex])
        """
        if let explanation = current.question.explanation, !explanation.isEmpty {
            ctx += "\n\nOfficial explanation from the study material:\n\(explanation)"
        }
        return ctx
    }
    
    /// Quick action buttons — seed the chat with a pre-built user message
    func requestExplanation() {
        sendChatMessage("Explain why the correct answer is right and why my answer was wrong.")
    }
    
    func requestMnemonic() {
        sendChatMessage("Give me a memorable mnemonic to help me remember this concept.")
    }
    
    /// Send a free-form follow-up message
    func sendChatMessage(_ text: String) {
        guard settingsManager.aiEnabled else { return }
        
        if settingsManager.confirmBeforeSending && chatMessages.isEmpty {
            pendingAIRequest = { [weak self] in self?.executeChatSend(text) }
            showConfirmation = true
        } else {
            executeChatSend(text)
        }
    }
    
    func confirmAIRequest() {
        showConfirmation = false
        pendingAIRequest?()
        pendingAIRequest = nil
    }
    
    func cancelAIRequest() {
        showConfirmation = false
        pendingAIRequest = nil
    }
    
    private func executeChatSend(_ text: String) {
        // Seed system + context on first message
        if chatMessages.isEmpty {
            chatMessages.append(ChatMessage(role: .system, content: settingsManager.systemPrompt))
            if let ctx = questionContextString() {
                chatMessages.append(ChatMessage(role: .user, content: ctx))
                chatMessages.append(ChatMessage(role: .assistant, content: "I can see the question and your answer. How can I help?"))
            }
        }
        
        chatMessages.append(ChatMessage(role: .user, content: text))
        
        logger.info("Chat send: \(text.prefix(60))...")
        
        Task { await performChatRequest() }
    }
    
    @MainActor
    private func performChatRequest() async {
        isLoadingAI = true
        aiError = nil
        displayedAIText = ""
        
        do {
            let response = try await aiService.sendChat(messages: chatMessages)
            chatMessages.append(ChatMessage(role: .assistant, content: response))
            isLoadingAI = false
            animateTypewriter(response)
            
            // Save mnemonic if it looks like one was requested
            if let current = currentQuestion,
               chatMessages.last(where: { $0.role == .user })?.content.lowercased().contains("mnemonic") == true {
                aiMnemonic = response
                let mnemonic = Mnemonic(questionId: current.question.id, text: response, createdAt: Date())
                try? databaseManager.saveMnemonic(mnemonic)
            }
        } catch let error as AIServiceError {
            logger.error("Chat error: \(String(describing: error))")
            aiError = error
            isLoadingAI = false
        } catch {
            logger.error("Chat error: \(error.localizedDescription)")
            aiError = .providerError("Unknown error")
            isLoadingAI = false
        }
    }
    
    @MainActor
    private func animateTypewriter(_ text: String) {
        typewriterTask?.cancel()
        displayedAIText = ""
        typewriterTask = Task {
            for char in text {
                guard !Task.isCancelled else { return }
                displayedAIText.append(char)
                try? await Task.sleep(for: .milliseconds(15))
            }
        }
    }
}
