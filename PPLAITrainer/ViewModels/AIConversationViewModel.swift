import Foundation
import os

@Observable
class AIConversationViewModel {
    private let aiService: AIServiceProtocol
    private let settingsManager: SettingsManager
    private let logger = Logger(subsystem: "com.pplaitrainer", category: "AIConversation")
    
    var chatMessages: [ChatMessage] = []
    var displayedAIText: String = ""
    var isLoadingAI = false
    var aiError: AIServiceError?
    var showConfirmation = false
    var showAISheet = false
    var requestCount = 0
    
    private var pendingAIRequest: (() -> Void)?
    private var typewriterTask: Task<Void, Never>?
    
    private let contextProvider: () -> String?
    let ttsService = TextToSpeechService()
    
    init(aiService: AIServiceProtocol, settingsManager: SettingsManager, contextProvider: @escaping () -> String?) {
        self.aiService = aiService
        self.settingsManager = settingsManager
        self.contextProvider = contextProvider
    }
    
    // MARK: - Quick Actions
    
    func requestExplanation() {
        guard let context = contextProvider() else { return }
        let systemMsg = ChatMessage(role: .system, content: context)
        let userMsg = ChatMessage(role: .user, content: "Explain why the correct answer is right.")
        executeRequest(system: systemMsg, user: userMsg)
    }
    
    func requestSimplification() {
        guard let context = contextProvider() else { return }
        let systemMsg = ChatMessage(role: .system, content: context)
        let userMsg = ChatMessage(role: .user, content: "Simplify this concept. Break it down into simple terms.")
        executeRequest(system: systemMsg, user: userMsg)
    }
    
    func requestAnalogy() {
        guard let context = contextProvider() else { return }
        let systemMsg = ChatMessage(role: .system, content: context)
        let userMsg = ChatMessage(role: .user, content: "Give me a real-world analogy to help me understand this concept.")
        executeRequest(system: systemMsg, user: userMsg)
    }
    
    func requestCommonMistakes() {
        guard let context = contextProvider() else { return }
        let systemMsg = ChatMessage(role: .system, content: context)
        let userMsg = ChatMessage(role: .user, content: "What do students commonly get wrong about this? What should I watch out for?")
        executeRequest(system: systemMsg, user: userMsg)
    }
    
    // MARK: - Chat
    
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
    
    // MARK: - Private
    
    private func executeRequest(system: ChatMessage, user: ChatMessage) {
        if settingsManager.confirmBeforeSending && chatMessages.isEmpty {
            pendingAIRequest = { [weak self] in
                self?.chatMessages = [system, user]
                Task { await self?.performChatRequest() }
            }
            showConfirmation = true
        } else {
            chatMessages = [system, user]
            Task { await performChatRequest() }
        }
    }
    
    private func executeChatSend(_ text: String) {
        if chatMessages.isEmpty, let context = contextProvider() {
            chatMessages.append(ChatMessage(role: .system, content: context))
        }
        chatMessages.append(ChatMessage(role: .user, content: text))
        Task { await performChatRequest() }
    }
    
    private func performChatRequest() async {
        guard settingsManager.aiEnabled else { return }
        
        isLoadingAI = true
        requestCount += 1
        aiError = nil
        displayedAIText = ""
        
        do {
            let response = try await aiService.sendChat(messages: chatMessages)
            chatMessages.append(ChatMessage(role: .assistant, content: response))
            await typewriterEffect(text: response)
        } catch let error as AIServiceError {
            aiError = error
            logger.error("AI request failed: \(error)")
        } catch {
            aiError = .providerError("Unknown error occurred")
            logger.error("AI request failed: \(error)")
        }
        
        isLoadingAI = false
    }
    
    func retryLastMessage() {
        aiError = nil
        Task { await performChatRequest() }
    }
    
    private func typewriterEffect(text: String) async {
        typewriterTask?.cancel()
        displayedAIText = ""
        
        typewriterTask = Task {
            for char in text {
                guard !Task.isCancelled else { return }
                displayedAIText.append(char)
                try? await Task.sleep(nanoseconds: 8_000_000)
            }
        }
        
        await typewriterTask?.value
    }
}
