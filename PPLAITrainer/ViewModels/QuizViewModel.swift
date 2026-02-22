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
    let gamificationService: GamificationService
    private let hapticService: HapticService
    private let soundService: SoundService
    private let questionAssetProvider: QuestionAssetProviding
    
    var questions: [PresentedQuestion] = []
    var currentIndex: Int = 0
    var selectedAnswer: Int? = nil
    var hasSubmitted: Bool = false
    var questionsAnswered: Int = 0
    var correctCount: Int = 0
    var answerHistory: [Bool] = [] // Track correct/incorrect for each question
    
    var aiMnemonic: String? = nil
    var aiHint: String? = nil
    var aiHintPayload: AIHintPayload? = nil
    var isLoadingHint: Bool = false
    var aiInlineResponse: String? = nil
    var isLoadingInlineAI: Bool = false
    var selectedExplainText: String? = nil
    var showAIResponseSheet: Bool = false
    var aiResponseSheetTitle: String = "AI Help"
    var aiResponseSheetBody: String? = nil
    var isLoadingAIResponseSheet: Bool = false
    
    enum AIRequestType: String {
        case explain = "explain"
        case simplify = "simplify"
        case analogy = "analogy"
        case commonMistakes = "mistakes"
        
        func prompt(using settingsManager: SettingsManager) -> String {
            switch self {
            case .explain:
                return settingsManager.prompt(for: .inlineExplain)
            case .simplify:
                return settingsManager.prompt(for: .inlineSimplify)
            case .analogy:
                return settingsManager.prompt(for: .inlineAnalogy)
            case .commonMistakes:
                return settingsManager.prompt(for: .inlineMistakes)
            }
        }
        
        var buttonLabel: String {
            switch self {
            case .explain: return "Explain"
            case .simplify: return "Simplify"
            case .analogy: return "Analogy"
            case .commonMistakes: return "Mistakes"
            }
        }
    }
    
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
    
    init(
        databaseManager: DatabaseManaging,
        srsEngine: SRSEngine,
        aiService: AIServiceProtocol,
        settingsManager: SettingsManager,
        gamificationService: GamificationService,
        hapticService: HapticService,
        soundService: SoundService,
        questionAssetProvider: QuestionAssetProviding
    ) {
        self.databaseManager = databaseManager
        self.srsEngine = srsEngine
        self.aiService = aiService
        self.settingsManager = settingsManager
        self.gamificationService = gamificationService
        self.hapticService = hapticService
        self.soundService = soundService
        self.questionAssetProvider = questionAssetProvider
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
                questions = try rawQuestions.shuffled().map { try createPresentedQuestion(from: $0) }
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
            questions = try rawQuestions.shuffled().map { try createPresentedQuestion(from: $0) }
            if !questions.isEmpty {
                logInteractionEvent(
                    name: "quiz_session_started",
                    questionId: nil,
                    metadata: "questionCount=\(questions.count);hint=quick_sheet;explain=selection_only"
                )
            }
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
        answerHistory.append(isCorrect)
        if isCorrect { 
            correctCount += 1
            showCorrectFlash = true
            hapticService.correctAnswer()
        } else {
            shakeIncorrect += 1
            showIncorrectFlash = true
            hapticService.incorrectAnswer()
        }
        questionsAnswered += 1
        logInteractionEvent(name: "quiz_answer_submitted", questionId: current.question.id, metadata: "isCorrect=\(isCorrect)")
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
        aiHint = nil
        aiHintPayload = nil
        isLoadingHint = false
        aiInlineResponse = nil
        isLoadingInlineAI = false
        showCorrectFlash = false
        showIncorrectFlash = false
        selectedExplainText = nil
        showAIResponseSheet = false
        aiResponseSheetTitle = "AI Help"
        aiResponseSheetBody = nil
        isLoadingAIResponseSheet = false
        aiConversation?.chatMessages = []
        if currentIndex >= questions.count {
            let accuracy = questionsAnswered > 0 ? Double(correctCount) / Double(questionsAnswered) : 0
            logInteractionEvent(name: "quiz_session_completed", questionId: nil, metadata: "answered=\(questionsAnswered);correct=\(correctCount);accuracy=\(accuracy)")
        }
    }
    
    func previousQuestion() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        selectedAnswer = nil
        hasSubmitted = false
        aiMnemonic = nil
        aiHint = nil
        aiHintPayload = nil
        isLoadingHint = false
        aiInlineResponse = nil
        isLoadingInlineAI = false
        showCorrectFlash = false
        showIncorrectFlash = false
        selectedExplainText = nil
        showAIResponseSheet = false
        aiResponseSheetTitle = "AI Help"
        aiResponseSheetBody = nil
        isLoadingAIResponseSheet = false
        aiConversation?.chatMessages = []
    }
    
    // MARK: - AI Chat
    
    /// Build the question context string that seeds every chat
    private func questionContextString() -> String? {
        guard let current = currentQuestion else { return nil }
        var ctx = """
        Question: \(current.question.text)
        
        Choices:
        \(current.shuffledAnswers.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))
        
        Your answer: \(selectedAnswer.map { current.shuffledAnswers[$0] } ?? "Not selected yet")
        Correct answer: \(current.shuffledAnswers[current.correctAnswerIndex])
        """
        
        // Include image attachments as context
        if !current.questionAttachments.isEmpty {
            let imageNames = current.questionAttachments.map { $0.filename }.joined(separator: ", ")
            ctx += "\n\nNote: This question includes diagram(s): \(imageNames)"
        }
        if !current.explanationAttachments.isEmpty {
            let imageNames = current.explanationAttachments.map { $0.filename }.joined(separator: ", ")
            ctx += "\n\nNote: The explanation includes diagram(s): \(imageNames)"
        }
        
        if selectedModelSupportsVision() {
            let attachmentFiles = (current.questionAttachments + current.explanationAttachments).map(\.filename)
            let multimodalPayloads: [String] = attachmentFiles.compactMap { name in
                guard let dataURL = base64DataURL(for: name) else { return nil }
                return "- \(name): \(dataURL)"
            }
            if !multimodalPayloads.isEmpty {
                ctx += "\n\nMultimodal attachment context (data URLs):\n\(multimodalPayloads.joined(separator: "\n"))"
            }
        }

        if let explanation = current.question.explanation, !explanation.isEmpty {
            ctx += "\n\nOfficial explanation:\n\(explanation)"
        }
        return ctx
    }

    private func selectedModelSupportsVision() -> Bool {
        let provider = AIProviderType(rawValue: settingsManager.selectedProvider) ?? .openai
        let modelId = provider.resolveModelId(settingsManager.selectedModel).lowercased()

        if modelId.contains("gemini-3") || modelId.contains("gpt-4o") || modelId.contains("gpt-4.1") {
            return true
        }
        return false
    }

    private func base64DataURL(for filename: String) -> String? {
        questionAssetProvider.imageDataURL(filename: filename)
    }
    
    // MARK: - AI Hint
    
    func getQuestionHint() {
        showHintSheet(forceRefresh: false)
    }

    func regenerateHint() {
        showHintSheet(forceRefresh: true)
    }

    func showHintSheet(forceRefresh: Bool = false) {
        guard !isLoadingHint, let current = currentQuestion else { return }
        let requestQuestionId = current.question.id
        let provider = AIProviderType(rawValue: settingsManager.selectedProvider) ?? .openai
        let modelId = provider.resolveModelId(settingsManager.selectedModel)
        let requestedImageCount = settingsManager.hintImageCount
        let responseType = hintCacheResponseType(provider: provider, modelId: modelId, imageCount: requestedImageCount)

        aiResponseSheetTitle = "Hint"
        aiResponseSheetBody = nil
        isLoadingAIResponseSheet = false

        logInteractionEvent(
            name: "quiz_hint_requested",
            questionId: requestQuestionId,
            metadata: "context=\(hasSubmitted ? "result" : "question");forceRefresh=\(forceRefresh);provider=\(provider.rawValue);imageCount=\(requestedImageCount)"
        )

        if !forceRefresh {
            if let cached = loadCachedHintPayload(
                questionId: requestQuestionId,
                responseType: responseType,
                fallbackProvider: provider.rawValue,
                fallbackModel: modelId
            ) {
                aiHintPayload = cached
                aiHint = cached.text
                aiResponseSheetBody = cached.text
                showAIResponseSheet = true
                logInteractionEvent(name: "quiz_hint_cache_hit", questionId: requestQuestionId, metadata: "type=\(responseType)")
                return
            }

            if let legacy = loadCachedHintPayload(
                questionId: requestQuestionId,
                responseType: "hint",
                fallbackProvider: provider.rawValue,
                fallbackModel: modelId
            ) {
                aiHintPayload = legacy
                aiHint = legacy.text
                aiResponseSheetBody = legacy.text
                showAIResponseSheet = true
                logInteractionEvent(name: "quiz_hint_cache_hit", questionId: requestQuestionId, metadata: "type=hint_legacy")
                return
            }
        }

        showAIResponseSheet = false
        isLoadingHint = true
        Task { @MainActor in
            defer { isLoadingHint = false }
            do {
                let questionImageContext = current.questionAttachments.isEmpty
                    ? "No question images attached."
                    : "Question images: \(current.questionAttachments.map(\.filename).joined(separator: ", "))"
                let visualRequested = (provider == .gemini || provider == .openai) ? "yes" : "no"

                let hintPrompt = settingsManager.renderPrompt(.hintRequest, values: [
                    "question": current.question.text,
                    "choiceA": current.shuffledAnswers[0],
                    "choiceB": current.shuffledAnswers[1],
                    "choiceC": current.shuffledAnswers[2],
                    "choiceD": current.shuffledAnswers[3],
                    "correctAnswer": current.shuffledAnswers[current.correctAnswerIndex],
                    "questionImageContext": questionImageContext,
                    "visualRequested": visualRequested,
                    "imageCount": "\(requestedImageCount)"
                ])

                let questionImages = current.questionAttachments.compactMap { attachment in
                    base64DataURL(for: attachment.filename).flatMap(parseDataURL)
                }

                let response = try await aiService.generateHint(
                    systemPrompt: settingsManager.systemPrompt,
                    prompt: hintPrompt,
                    questionImages: questionImages,
                    imageCount: requestedImageCount
                )

                let payload = try persistHintPayload(
                    response: response,
                    questionId: requestQuestionId,
                    responseType: responseType,
                    provider: provider,
                    modelId: modelId
                )

                guard currentQuestion?.question.id == requestQuestionId else { return }
                aiHintPayload = payload
                aiHint = payload.text
                aiResponseSheetBody = payload.text
                showAIResponseSheet = true
                logInteractionEvent(
                    name: "quiz_hint_generated",
                    questionId: requestQuestionId,
                    metadata: "images=\(payload.images.count);provider=\(provider.rawValue)"
                )
            } catch {
                guard currentQuestion?.question.id == requestQuestionId else { return }
                let fallbackText = "Unable to generate hint. Please try again."
                let payload = AIHintPayload(
                    text: fallbackText,
                    images: [],
                    provider: provider.rawValue,
                    model: modelId,
                    createdAt: Date()
                )
                aiHintPayload = payload
                aiHint = fallbackText
                aiResponseSheetBody = fallbackText
                showAIResponseSheet = true
                logInteractionEvent(
                    name: "quiz_hint_failed",
                    questionId: requestQuestionId,
                    metadata: "provider=\(provider.rawValue)"
                )
            }
        }
    }
    
    func requestInlineAI(type: AIRequestType) {
        guard let current = currentQuestion else { return }
        logInteractionEvent(name: "quiz_inline_ai_requested", questionId: current.question.id, metadata: "type=\(type.rawValue)")
        let responseType = inlineAIResponseType(for: type)
        
        // Check cache first
        if let responseType,
           let cached = try? databaseManager.fetchAIResponse(questionId: current.question.id, responseType: responseType) {
                aiInlineResponse = cached.response
                // Add to conversation history
                aiConversation?.chatMessages.append(ChatMessage(role: .user, content: type.prompt(using: settingsManager)))
                aiConversation?.chatMessages.append(ChatMessage(role: .assistant, content: cached.response))
                return
        }
        
        isLoadingInlineAI = true
        Task { @MainActor in
            do {
                let selectedAnswerText: String
                let studentAnswerStatus: String
                if let selectedAnswer, current.shuffledAnswers.indices.contains(selectedAnswer) {
                    selectedAnswerText = current.shuffledAnswers[selectedAnswer]
                    studentAnswerStatus = selectedAnswer == current.correctAnswerIndex ? "correct" : "incorrect"
                } else {
                    selectedAnswerText = "No student answer submitted."
                    studentAnswerStatus = "unanswered"
                }

                let choices = current.shuffledAnswers.map { "- \($0)" }.joined(separator: "\n")
                let context = """
                Question: \(current.question.text)
                
                Choices (order may vary each session):
                \(choices)
                
                Correct answer text (use this exact wording): \(current.shuffledAnswers[current.correctAnswerIndex])
                Student selected answer text: \(selectedAnswerText)
                Student answer status: \(studentAnswerStatus)
                
                Official explanation:
                \(current.question.explanation ?? "")
                """
                
                let basePrompt = type.prompt(using: settingsManager).replacingOccurrences(of: "{{context}}", with: context)
                let explainOnlyGuidance: String = type == .explain
                    ? "- For Explain, explicitly compare the student's selected answer to the correct answer and explain why one is right and the other is wrong when applicable.\n"
                    : ""
                let prompt = """
                \(basePrompt)

                Important constraints:
                - Do not reference option letters (A/B/C/D) or option position.
                - Refer to the correct answer by answer text only.
                \(explainOnlyGuidance)
                """
                let messages = [ChatMessage(role: .system, content: settingsManager.systemPrompt),
                               ChatMessage(role: .user, content: prompt)]
                
                let response = try await aiService.sendChat(messages: messages)
                aiInlineResponse = response
                
                // Add to conversation history
                aiConversation?.chatMessages.append(ChatMessage(role: .user, content: type.prompt(using: settingsManager)))
                aiConversation?.chatMessages.append(ChatMessage(role: .assistant, content: response))
                
                // Cache non-explain responses only.
                if let responseType {
                    let cache = AIResponseCache(
                        id: nil,
                        questionId: current.question.id,
                        responseType: responseType,
                        response: response,
                        createdAt: Date()
                    )
                    try? databaseManager.saveAIResponse(cache)
                }
                logInteractionEvent(name: "quiz_inline_ai_generated", questionId: current.question.id, metadata: "type=\(type.rawValue)")
                
                isLoadingInlineAI = false
            } catch {
                aiInlineResponse = "Unable to generate response. Please try again."
                logInteractionEvent(name: "quiz_inline_ai_failed", questionId: current.question.id, metadata: "type=\(type.rawValue)")
                isLoadingInlineAI = false
            }
        }
    }

    // MARK: - Contextual Explain

    func updateSelectedExplainText(_ text: String?) {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines)
        selectedExplainText = (trimmed?.isEmpty == false) ? trimmed : nil
    }

    func explainSelectedText() {
        guard settingsManager.aiEnabled,
              let current = currentQuestion,
              let selectedExplainText else { return }
        showAIResponseSheet = true
        aiResponseSheetTitle = "Explain Selection"
        aiResponseSheetBody = nil
        isLoadingAIResponseSheet = true
        
        let normalizedSelectedText = selectedExplainText.trimmingCharacters(in: .whitespacesAndNewlines)
        let responseType = contextualExplainCacheKey(for: normalizedSelectedText)
        
        if let cached = try? databaseManager.fetchAIResponse(questionId: current.question.id, responseType: responseType) {
            aiResponseSheetBody = cached.response
            isLoadingAIResponseSheet = false
            logInteractionEvent(name: "quiz_contextual_explain_cache_hit", questionId: current.question.id, metadata: "selection=\(normalizedSelectedText.prefix(60))")
            return
        }

        logInteractionEvent(name: "quiz_contextual_explain_requested", questionId: current.question.id, metadata: "selection=\(selectedExplainText.prefix(60))")
        
        Task { @MainActor in
            do {
                let prompt = settingsManager.renderPrompt(.contextualExplain, values: [
                    "selectedText": normalizedSelectedText,
                    "question": current.question.text,
                    "correctAnswer": current.shuffledAnswers[current.correctAnswerIndex],
                    "officialExplanation": current.question.explanation.map { "Official explanation: \($0)" } ?? ""
                ])
                
                let messages = [ChatMessage(role: .system, content: settingsManager.systemPrompt),
                               ChatMessage(role: .user, content: prompt)]
                
                let response = try await aiService.sendChat(messages: messages)
                aiResponseSheetBody = response
                isLoadingAIResponseSheet = false
                
                let cache = AIResponseCache(
                    id: nil,
                    questionId: current.question.id,
                    responseType: responseType,
                    response: response,
                    createdAt: Date()
                )
                try? databaseManager.saveAIResponse(cache)
                logInteractionEvent(name: "quiz_contextual_explain_generated", questionId: current.question.id, metadata: "selection=\(normalizedSelectedText.prefix(60))")
            } catch {
                aiResponseSheetBody = "Unable to generate explanation. Please try again."
                isLoadingAIResponseSheet = false
                logInteractionEvent(name: "quiz_contextual_explain_failed", questionId: current.question.id, metadata: "selection=\(normalizedSelectedText.prefix(60))")
            }
        }
    }

    private func hintCacheResponseType(provider: AIProviderType, modelId: String, imageCount: Int) -> String {
        "hint_v2_\(provider.rawValue)_\(stableHash(modelId.lowercased()))_img\(max(1, min(3, imageCount)))"
    }

    private func loadCachedHintPayload(questionId: Int64, responseType: String, fallbackProvider: String, fallbackModel: String) -> AIHintPayload? {
        guard let cached = try? databaseManager.fetchAIResponse(questionId: questionId, responseType: responseType) else {
            return nil
        }
        return decodeHintPayload(from: cached.response, fallbackProvider: fallbackProvider, fallbackModel: fallbackModel)
    }

    private func decodeHintPayload(from response: String, fallbackProvider: String, fallbackModel: String) -> AIHintPayload? {
        if let data = response.data(using: .utf8),
           let payload = try? JSONDecoder().decode(AIHintPayload.self, from: data) {
            return payloadWithExistingImages(payload)
        }

        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return AIHintPayload(
            text: trimmed,
            images: [],
            provider: fallbackProvider,
            model: fallbackModel,
            createdAt: Date()
        )
    }

    private func persistHintPayload(
        response: AIHintResponse,
        questionId: Int64,
        responseType: String,
        provider: AIProviderType,
        modelId: String
    ) throws -> AIHintPayload {
        if let existing = try? databaseManager.fetchAIResponse(questionId: questionId, responseType: responseType),
           let decoded = decodeHintPayload(from: existing.response, fallbackProvider: provider.rawValue, fallbackModel: modelId) {
            deleteHintImageFiles(from: decoded)
        }

        let imageLimit = max(1, min(3, settingsManager.hintImageCount))
        let imageReferences = try response.images
            .prefix(imageLimit)
            .map { image in
                let imageURL = try persistHintImageData(image.data, mimeType: image.mimeType, questionId: questionId)
                return AIHintPayload.ImageReference(path: imageURL.path, mimeType: image.mimeType)
            }

        let trimmedText = response.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let payload = AIHintPayload(
            text: trimmedText.isEmpty ? "Use the key concept in the stem and eliminate options that conflict with basic flight principles." : trimmedText,
            images: imageReferences,
            provider: provider.rawValue,
            model: modelId,
            createdAt: Date()
        )

        let encoded = try JSONEncoder().encode(payload)
        guard let encodedString = String(data: encoded, encoding: .utf8) else {
            throw AIServiceError.providerError("Unable to encode hint cache payload")
        }

        let cache = AIResponseCache(
            id: nil,
            questionId: questionId,
            responseType: responseType,
            response: encodedString,
            createdAt: Date()
        )
        try databaseManager.saveAIResponse(cache)
        return payloadWithExistingImages(payload)
    }

    private func payloadWithExistingImages(_ payload: AIHintPayload) -> AIHintPayload {
        var filtered = payload
        filtered.images = payload.images.filter { FileManager.default.fileExists(atPath: $0.path) }
        return filtered
    }

    private func deleteHintImageFiles(from payload: AIHintPayload) {
        let fileManager = FileManager.default
        for image in payload.images where fileManager.fileExists(atPath: image.path) {
            try? fileManager.removeItem(atPath: image.path)
        }
    }

    private func persistHintImageData(_ data: Data, mimeType: String, questionId: Int64) throws -> URL {
        let directory = try hintImageCacheDirectory()
        let ext = fileExtension(for: mimeType)
        let filename = "q\(questionId)_\(UUID().uuidString).\(ext)"
        let url = directory.appendingPathComponent(filename, isDirectory: false)
        try data.write(to: url, options: .atomic)
        return url
    }

    private func hintImageCacheDirectory() throws -> URL {
        let fileManager = FileManager.default
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let datasetId = settingsManager.activeDatasetId ?? "default"
        let profileId = settingsManager.profileId(for: datasetId)
        let directory = appSupport
            .appendingPathComponent("PPLAITrainer", isDirectory: true)
            .appendingPathComponent("AIHintCache", isDirectory: true)
            .appendingPathComponent(datasetId, isDirectory: true)
            .appendingPathComponent(profileId, isDirectory: true)

        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    private func fileExtension(for mimeType: String) -> String {
        switch mimeType.lowercased() {
        case "image/jpeg": return "jpg"
        case "image/webp": return "webp"
        default: return "png"
        }
    }

    private func parseDataURL(_ dataURL: String) -> AIInputImage? {
        guard dataURL.hasPrefix("data:"),
              let commaIndex = dataURL.firstIndex(of: ",") else {
            return nil
        }
        let metadataStart = dataURL.index(dataURL.startIndex, offsetBy: 5)
        let metadata = String(dataURL[metadataStart..<commaIndex])
        let components = metadata.components(separatedBy: ";")
        guard let mimeType = components.first,
              metadata.contains("base64") else {
            return nil
        }
        let payloadStart = dataURL.index(after: commaIndex)
        let base64Payload = String(dataURL[payloadStart...])
        guard !base64Payload.isEmpty else { return nil }
        return AIInputImage(mimeType: mimeType, base64Data: base64Payload)
    }
    
    // MARK: - Visual Prompt Generation

    func generateVisualPrompt() -> String {
        guard let current = currentQuestion else { return "" }

        return settingsManager.renderPrompt(.visualGeneration, values: [
            "mediaType": "image",
            "question": current.question.text,
            "correctAnswer": current.shuffledAnswers[current.correctAnswerIndex],
            "officialExplanation": current.question.explanation ?? ""
        ])
    }
    
    // MARK: - Session Persistence
    
    func saveSessionState(categoryId: Int64?, categoryName: String?) {
        guard !questions.isEmpty else { return }
        let questionIds = questions.map { String($0.question.id) }.joined(separator: ",")
        let answersData = try? JSONEncoder().encode(questions.indices.map { _ in nil as Int? })
        let answersString = answersData.flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        
        let session = QuizSessionState(
            id: nil,
            categoryId: categoryId,
            categoryName: categoryName,
            currentIndex: currentIndex,
            questionIds: questionIds,
            answers: answersString,
            timestamp: Date()
        )
        try? databaseManager.saveQuizSession(session)
    }
    
    func restoreSession(from state: QuizSessionState) {
        Task { @MainActor in
            let ids = state.questionIds.split(separator: ",").compactMap { Int64($0) }
            let rawQuestions = ids.compactMap { try? databaseManager.fetchQuestion(id: $0) }
            questions = try rawQuestions.map { try createPresentedQuestion(from: $0) }
            currentIndex = state.currentIndex
        }
    }
    
    func clearSavedSession() {
        try? databaseManager.clearQuizSession()
    }

    // MARK: - Analytics

    private func logInteractionEvent(name: String, questionId: Int64?, metadata: String?) {
        try? databaseManager.logInteractionEvent(name: name, questionId: questionId, metadata: metadata)
    }
    
    private func contextualExplainCacheKey(for selectedText: String) -> String {
        "context_explain_\(stableHash(selectedText.lowercased()))"
    }

    private func inlineAIResponseType(for type: AIRequestType) -> String? {
        switch type {
        case .explain:
            return nil
        case .simplify, .analogy, .commonMistakes:
            return "inline_v3_\(type.rawValue)"
        }
    }
    
    private func stableHash(_ input: String) -> UInt64 {
        input.utf8.reduce(5381) { hash, byte in
            ((hash << 5) &+ hash) &+ UInt64(byte)
        }
    }
}
