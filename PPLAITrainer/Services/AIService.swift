import Foundation
import os

private let logger = Logger(subsystem: "com.pplaitrainer", category: "AIService")

enum AIServiceError: Error {
    case noAPIKey
    case noNetwork
    case providerError(String)
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: ChatRole
    let content: String
}

enum ChatRole: String {
    case system, user, assistant
}

protocol AIServiceProtocol {
    func sendChat(messages: [ChatMessage]) async throws -> String
}

final class AIService: AIServiceProtocol {
    private let keychainStore: KeychainStore
    private let settingsManager: SettingsManager
    private let networkMonitor: NetworkMonitor
    
    init(keychainStore: KeychainStore, settingsManager: SettingsManager, networkMonitor: NetworkMonitor) {
        self.keychainStore = keychainStore
        self.settingsManager = settingsManager
        self.networkMonitor = networkMonitor
    }
    
    func sendChat(messages: [ChatMessage]) async throws -> String {
        guard settingsManager.aiEnabled else {
            throw AIServiceError.providerError("AI features are disabled")
        }

        guard let resolved = try? resolveProvider() else {
            logger.info("Falling back to offline AI response")
            return offlineFallbackResponse(messages: messages)
        }

        let (provider, apiKey, config) = resolved
        logger.info("Sending chat with \(messages.count) messages to \(provider.rawValue)")

        if provider == .gemini {
            return try await makeGeminiChat(config: config, apiKey: apiKey, messages: messages)
        } else {
            return try await makeOpenAIChat(config: config, apiKey: apiKey, messages: messages)
        }
    }
    
    private func resolveProvider() throws -> (AIProviderType, String, AIProviderConfig) {
        guard networkMonitor.isConnected else {
            logger.warning("AI request blocked: no network")
            throw AIServiceError.noNetwork
        }
        let provider = AIProviderType(rawValue: settingsManager.selectedProvider) ?? .openai
        guard let apiKey = try keychainStore.read(provider: provider.rawValue), !apiKey.isEmpty else {
            logger.warning("AI request blocked: no API key for \(provider.rawValue)")
            throw AIServiceError.noAPIKey
        }
        return (provider, apiKey, AIProviderConfig.config(for: provider, modelId: settingsManager.selectedModel))
    }
    
    // MARK: - OpenAI-style (OpenAI, Grok)

    private func makeOpenAIChat(config: AIProviderConfig, apiKey: String, messages: [ChatMessage]) async throws -> String {
        let payload = messages.map { ["role": $0.role.rawValue, "content": $0.content] }
        return try await openAICall(config: config, apiKey: apiKey, messages: payload)
    }
    
    private func openAICall(config: AIProviderConfig, apiKey: String, messages: [[String: String]]) async throws -> String {
        var request = URLRequest(url: URL(string: config.baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["model": config.modelName, "messages": messages]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        logger.debug("POST \(config.baseURL) model=\(config.modelName)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.providerError("No HTTP response")
        }
        
        logger.info("HTTP \(httpResponse.statusCode) from \(config.baseURL)")
        
        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "no body"
            logger.error("API error \(httpResponse.statusCode): \(body)")
            throw AIServiceError.providerError("Request failed (HTTP \(httpResponse.statusCode))")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            logger.error("Invalid response format: \(String(data: data, encoding: .utf8) ?? "")")
            throw AIServiceError.providerError("Invalid response format")
        }
        
        return content
    }
    

    private func offlineFallbackResponse(messages: [ChatMessage]) -> String {
        let latestUser = messages.last { $0.role == .user }?.content ?? ""
        let context = messages.first { $0.role == .system }?.content ?? ""

        return """
        Offline mode is active (no API key/network).

        Quick guidance:
        • Focus on the question stem and eliminate clearly incorrect options first.
        • Re-check aviation keywords (altitude, heading, QNH/QFE, cloud/airspace terms).
        • Use the explanation text as your ground truth for final review.

        Your request: \(latestUser)

        Context snippet:
        \(context.prefix(320))
        """
    }
    // MARK: - Gemini

    private func makeGeminiChat(config: AIProviderConfig, apiKey: String, messages: [ChatMessage]) async throws -> String {
        let contents: [[String: Any]] = messages.filter { $0.role != .system }.map { msg in
            let role = msg.role == .assistant ? "model" : "user"
            return ["role": role, "parts": [["text": msg.content]]]
        }
        // Prepend system prompt to first user message context
        let systemMsg = messages.first { $0.role == .system }?.content ?? ""
        var adjusted = contents
        if !systemMsg.isEmpty, var first = adjusted.first, let parts = first["parts"] as? [[String: String]], let text = parts.first?["text"] {
            first["parts"] = [["text": "\(systemMsg)\n\n\(text)"]]
            adjusted[0] = first
        }
        return try await geminiCall(config: config, apiKey: apiKey, contents: adjusted)
    }
    
    private func geminiCall(config: AIProviderConfig, apiKey: String, contents: [[String: Any]]) async throws -> String {
        let urlString = "\(config.baseURL)?key=\(apiKey)"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["contents": contents]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        logger.debug("POST \(config.baseURL) (Gemini)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.providerError("No HTTP response")
        }
        
        logger.info("HTTP \(httpResponse.statusCode) from Gemini")
        
        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "no body"
            logger.error("Gemini error \(httpResponse.statusCode): \(body)")
            throw AIServiceError.providerError("Request failed (HTTP \(httpResponse.statusCode))")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            logger.error("Invalid Gemini response: \(String(data: data, encoding: .utf8) ?? "")")
            throw AIServiceError.providerError("Invalid response format")
        }
        
        return text
    }
}
