import Foundation
import os

private let logger = Logger(subsystem: "com.pplaitrainer", category: "AIService")

enum AIServiceError: Error {
    case noAPIKey
    case noNetwork
    case providerError(String)
}

struct AIInputImage {
    let mimeType: String
    let base64Data: String

    var dataURL: String {
        "data:\(mimeType);base64,\(base64Data)"
    }
}

struct AIHintGeneratedImage {
    let mimeType: String
    let data: Data
}

struct AIHintResponse {
    let text: String
    let images: [AIHintGeneratedImage]
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
    func generateHint(systemPrompt: String, prompt: String, questionImages: [AIInputImage], imageCount: Int) async throws -> AIHintResponse
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

    func generateHint(systemPrompt: String, prompt: String, questionImages: [AIInputImage], imageCount: Int) async throws -> AIHintResponse {
        guard settingsManager.aiEnabled else {
            throw AIServiceError.providerError("AI features are disabled")
        }

        let clampedImageCount = max(0, min(3, imageCount))
        let textFallbackMessages = [
            ChatMessage(role: .system, content: systemPrompt),
            ChatMessage(role: .user, content: prompt)
        ]

        guard let resolved = try? resolveProvider() else {
            logger.info("Falling back to offline hint response")
            let fallback = offlineFallbackResponse(messages: textFallbackMessages)
            return AIHintResponse(text: fallback, images: [])
        }

        let (provider, apiKey, config) = resolved

        switch provider {
        case .gemini:
            if clampedImageCount == 0 {
                do {
                    return try await makeGeminiTextOnlyHint(
                        config: config,
                        apiKey: apiKey,
                        systemPrompt: systemPrompt,
                        prompt: prompt,
                        questionImages: questionImages
                    )
                } catch {
                    logger.warning("Gemini text-only hint with images failed. Falling back to plain chat hint: \(error.localizedDescription, privacy: .public)")
                    let text = try await makeGeminiChat(config: config, apiKey: apiKey, messages: textFallbackMessages)
                    return AIHintResponse(text: text, images: [])
                }
            }
            do {
                return try await makeGeminiHint(
                    config: config,
                    apiKey: apiKey,
                    systemPrompt: systemPrompt,
                    prompt: prompt,
                    questionImages: questionImages,
                    imageCount: clampedImageCount
                )
            } catch {
                logger.warning("Gemini multimodal hint failed. Falling back to text-only hint: \(error.localizedDescription, privacy: .public)")
                do {
                    return try await makeGeminiTextOnlyHint(
                        config: config,
                        apiKey: apiKey,
                        systemPrompt: systemPrompt,
                        prompt: prompt,
                        questionImages: questionImages
                    )
                } catch {
                    let text = try await makeGeminiChat(config: config, apiKey: apiKey, messages: textFallbackMessages)
                    return AIHintResponse(text: text, images: [])
                }
            }
        case .openai:
            if clampedImageCount == 0 {
                do {
                    return try await makeOpenAITextOnlyHint(
                        model: config.modelName,
                        apiKey: apiKey,
                        systemPrompt: systemPrompt,
                        prompt: prompt,
                        questionImages: questionImages
                    )
                } catch {
                    logger.warning("OpenAI text-only hint with images failed. Falling back to plain chat hint: \(error.localizedDescription, privacy: .public)")
                    let text = try await makeOpenAIChat(config: config, apiKey: apiKey, messages: textFallbackMessages)
                    return AIHintResponse(text: text, images: [])
                }
            }
            do {
                return try await makeOpenAIHint(
                    model: config.modelName,
                    apiKey: apiKey,
                    systemPrompt: systemPrompt,
                    prompt: prompt,
                    questionImages: questionImages,
                    imageCount: clampedImageCount
                )
            } catch {
                logger.warning("OpenAI multimodal hint failed. Falling back to text-only hint: \(error.localizedDescription, privacy: .public)")
                do {
                    return try await makeOpenAITextOnlyHint(
                        model: config.modelName,
                        apiKey: apiKey,
                        systemPrompt: systemPrompt,
                        prompt: prompt,
                        questionImages: questionImages
                    )
                } catch {
                    let text = try await makeOpenAIChat(config: config, apiKey: apiKey, messages: textFallbackMessages)
                    return AIHintResponse(text: text, images: [])
                }
            }
        case .grok:
            let text = try await makeOpenAIChat(config: config, apiKey: apiKey, messages: textFallbackMessages)
            return AIHintResponse(text: text, images: [])
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

    private func makeOpenAIHint(
        model: String,
        apiKey: String,
        systemPrompt: String,
        prompt: String,
        questionImages: [AIInputImage],
        imageCount: Int
    ) async throws -> AIHintResponse {
        var responseText: String?
        var generatedImages: [AIHintGeneratedImage] = []

        for idx in 0..<max(1, imageCount) {
            let variantSuffix = imageCount > 1
                ? "\n\nCreate a distinct visual variation \(idx + 1) of \(imageCount)."
                : ""
            let combinedPrompt = deepHintMultimodalDirective + "\n\n" + prompt + variantSuffix
            let result = try await openAIHintCall(
                model: model,
                apiKey: apiKey,
                systemPrompt: systemPrompt,
                prompt: combinedPrompt,
                questionImages: questionImages,
                enableImageGeneration: true
            )
            if responseText == nil, !result.text.isEmpty {
                responseText = result.text
            }
            if let firstImage = result.images.first {
                generatedImages.append(firstImage)
            }
        }

        if responseText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            let textOnly = try await makeOpenAITextOnlyHint(
                model: model,
                apiKey: apiKey,
                systemPrompt: systemPrompt,
                prompt: deepHintMultimodalDirective + "\n\n" + prompt,
                questionImages: questionImages
            )
            responseText = textOnly.text
        }

        let finalText = responseText?.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = "Use the key concept in the stem and eliminate options that conflict with basic flight principles."
        return AIHintResponse(text: (finalText?.isEmpty == false) ? (finalText ?? fallback) : fallback, images: generatedImages)
    }

    private func makeOpenAITextOnlyHint(
        model: String,
        apiKey: String,
        systemPrompt: String,
        prompt: String,
        questionImages: [AIInputImage]
    ) async throws -> AIHintResponse {
        let result = try await openAIHintCall(
            model: model,
            apiKey: apiKey,
            systemPrompt: systemPrompt,
            prompt: prompt,
            questionImages: questionImages,
            enableImageGeneration: false
        )
        let fallback = "Use the key concept in the stem and eliminate options that conflict with basic flight principles."
        let finalText = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
        return AIHintResponse(text: finalText.isEmpty ? fallback : finalText, images: [])
    }

    private func openAIHintCall(
        model: String,
        apiKey: String,
        systemPrompt: String,
        prompt: String,
        questionImages: [AIInputImage],
        enableImageGeneration: Bool
    ) async throws -> AIHintResponse {
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var userContent: [[String: Any]] = [["type": "input_text", "text": prompt]]
        userContent.append(contentsOf: questionImages.map { image in
            ["type": "input_image", "image_url": image.dataURL]
        })

        var body: [String: Any] = [
            "model": model,
            "input": [
                [
                    "role": "system",
                    "content": [["type": "input_text", "text": systemPrompt]]
                ],
                [
                    "role": "user",
                    "content": userContent
                ]
            ]
        ]
        if enableImageGeneration {
            body["tools"] = [["type": "image_generation"]]
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        logger.debug("POST /v1/responses (OpenAI multimodal hint) model=\(model)")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.providerError("No HTTP response")
        }

        logger.info("HTTP \(httpResponse.statusCode) from OpenAI responses")

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "no body"
            logger.error("OpenAI multimodal error \(httpResponse.statusCode): \(body)")
            throw AIServiceError.providerError("Request failed (HTTP \(httpResponse.statusCode))")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            logger.error("Invalid OpenAI multimodal response: \(String(data: data, encoding: .utf8) ?? "")")
            throw AIServiceError.providerError("Invalid response format")
        }

        var textParts: [String] = []
        if let outputText = json["output_text"] as? String, !outputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textParts.append(outputText)
        }

        var images: [AIHintGeneratedImage] = []
        if let output = json["output"] as? [[String: Any]] {
            for item in output {
                if enableImageGeneration, let itemType = item["type"] as? String, itemType == "image_generation_call" {
                    if let result = item["result"] as? String,
                       let data = Data(base64Encoded: result) {
                        images.append(AIHintGeneratedImage(mimeType: "image/png", data: data))
                    } else if let resultArray = item["result"] as? [String] {
                        for encoded in resultArray {
                            if let data = Data(base64Encoded: encoded) {
                                images.append(AIHintGeneratedImage(mimeType: "image/png", data: data))
                            }
                        }
                    }
                }

                if let content = item["content"] as? [[String: Any]] {
                    for part in content {
                        if let partType = part["type"] as? String, partType == "output_text",
                           let text = part["text"] as? String,
                           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            textParts.append(text)
                        }
                    }
                }
            }
        }

        let text = textParts.joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return AIHintResponse(text: text, images: images)
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

    private func makeGeminiHint(
        config: AIProviderConfig,
        apiKey: String,
        systemPrompt: String,
        prompt: String,
        questionImages: [AIInputImage],
        imageCount: Int
    ) async throws -> AIHintResponse {
        let resolvedModel = geminiHintModel(from: config.modelName)
        let hintConfig = AIProviderConfig(
            baseURL: "https://generativelanguage.googleapis.com/v1beta/models/\(resolvedModel):generateContent",
            modelName: resolvedModel
        )

        var responseText: String?
        var generatedImages: [AIHintGeneratedImage] = []

        for idx in 0..<max(1, imageCount) {
            let variantSuffix = imageCount > 1
                ? "\n\nCreate a distinct visual variation \(idx + 1) of \(imageCount)."
                : ""
            let combinedPrompt = "\(systemPrompt)\n\n\(deepHintMultimodalDirective)\n\n\(prompt)\(variantSuffix)"
            let result = try await geminiHintCall(
                config: hintConfig,
                apiKey: apiKey,
                combinedPrompt: combinedPrompt,
                questionImages: questionImages,
                responseModalities: ["TEXT", "IMAGE"],
                parseImages: true
            )
            if responseText == nil, !result.text.isEmpty {
                responseText = result.text
            }
            if let firstImage = result.images.first {
                generatedImages.append(firstImage)
            }
        }

        if responseText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            let textOnly = try await makeGeminiTextOnlyHint(
                config: config,
                apiKey: apiKey,
                systemPrompt: systemPrompt,
                prompt: deepHintMultimodalDirective + "\n\n" + prompt,
                questionImages: questionImages
            )
            responseText = textOnly.text
        }

        let finalText = responseText?.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = "Use the key concept in the stem and eliminate options that conflict with basic flight principles."
        return AIHintResponse(text: (finalText?.isEmpty == false) ? (finalText ?? fallback) : fallback, images: generatedImages)
    }

    private var deepHintMultimodalDirective: String {
        """
        Deep-hint output contract:
        - Return BOTH modalities in the same response: (1) a concise textual hint and (2) visual diagram output.
        - The text hint must never be empty and should stay exam-focused.
        """
    }

    private func makeGeminiTextOnlyHint(
        config: AIProviderConfig,
        apiKey: String,
        systemPrompt: String,
        prompt: String,
        questionImages: [AIInputImage]
    ) async throws -> AIHintResponse {
        let result = try await geminiHintCall(
            config: config,
            apiKey: apiKey,
            combinedPrompt: "\(systemPrompt)\n\n\(prompt)",
            questionImages: questionImages,
            responseModalities: ["TEXT"],
            parseImages: false
        )
        let fallback = "Use the key concept in the stem and eliminate options that conflict with basic flight principles."
        let finalText = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
        return AIHintResponse(text: finalText.isEmpty ? fallback : finalText, images: [])
    }

    private func geminiHintCall(
        config: AIProviderConfig,
        apiKey: String,
        combinedPrompt: String,
        questionImages: [AIInputImage],
        responseModalities: [String],
        parseImages: Bool
    ) async throws -> AIHintResponse {
        let urlString = "\(config.baseURL)?key=\(apiKey)"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var parts: [[String: Any]] = [["text": combinedPrompt]]
        parts.append(contentsOf: questionImages.map { image in
            [
                "inlineData": [
                    "mimeType": image.mimeType,
                    "data": image.base64Data
                ]
            ]
        })

        let body: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": parts
                ]
            ],
            "generationConfig": [
                "responseModalities": responseModalities
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        logger.debug("POST \(config.baseURL) (Gemini multimodal hint)")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.providerError("No HTTP response")
        }

        logger.info("HTTP \(httpResponse.statusCode) from Gemini multimodal")

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "no body"
            logger.error("Gemini multimodal error \(httpResponse.statusCode): \(body)")
            throw AIServiceError.providerError("Request failed (HTTP \(httpResponse.statusCode))")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]] else {
            logger.error("Invalid Gemini multimodal response: \(String(data: data, encoding: .utf8) ?? "")")
            throw AIServiceError.providerError("Invalid response format")
        }

        var textParts: [String] = []
        var images: [AIHintGeneratedImage] = []

        for part in parts {
            if let isThought = part["thought"] as? Bool, isThought {
                continue
            }
            if let text = part["text"] as? String,
               !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                textParts.append(text)
            }

            if parseImages {
                let inlineAny = (part["inlineData"] as? [String: Any]) ?? (part["inline_data"] as? [String: Any])
                if let inlineAny,
                   let encoded = inlineAny["data"] as? String,
                   let decoded = Data(base64Encoded: encoded) {
                    let mime = (inlineAny["mimeType"] as? String) ?? (inlineAny["mime_type"] as? String) ?? "image/png"
                    images.append(AIHintGeneratedImage(mimeType: mime, data: decoded))
                }
            }
        }

        return AIHintResponse(text: textParts.joined(separator: "\n\n"), images: images)
    }

    private func geminiHintModel(from configuredModel: String) -> String {
        let normalized = configuredModel.lowercased()
        if normalized.contains("image") {
            return configuredModel
        }
        return "gemini-3-pro-image-preview"
    }
}
