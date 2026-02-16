import Foundation

struct AIModel: Identifiable, Equatable {
    let id: String          // API model name (e.g. "gpt-4.1-nano")
    let displayName: String
    let subtitle: String
    let description: String // Longer explanation of capabilities
}

enum AIProviderType: String, CaseIterable, Identifiable {
    case openai
    case gemini
    case grok

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openai: "OpenAI"
        case .gemini: "Gemini"
        case .grok: "Grok"
        }
    }

    var availableModels: [AIModel] {
        switch self {
        case .openai:
            [
                AIModel(
                    id: "gpt-4.1-nano",
                    displayName: "GPT-4.1 Nano",
                    subtitle: "Cheapest",
                    description: "Fastest and cheapest OpenAI model. Best for simple questions, quick lookups, and high-volume tasks where cost matters most."
                ),
                AIModel(
                    id: "gpt-4.1-mini",
                    displayName: "GPT-4.1 Mini",
                    subtitle: "Fast & affordable",
                    description: "Strong balance of speed and intelligence. Great all-rounder for explanations, summaries, and everyday study help."
                ),
                AIModel(
                    id: "gpt-5-mini",
                    displayName: "GPT-5 Mini",
                    subtitle: "Fast GPT-5",
                    description: "A faster, cheaper version of GPT-5 for well-defined tasks. Great balance of next-gen intelligence and affordability."
                ),
                AIModel(
                    id: "gpt-4.1",
                    displayName: "GPT-4.1",
                    subtitle: "Smartest non-reasoning",
                    description: "Most capable general-purpose model in the 4.1 family. Excels at detailed analysis, nuanced explanations, and complex multi-step instructions."
                ),
                AIModel(
                    id: "o4-mini",
                    displayName: "o4 Mini",
                    subtitle: "Reasoning model",
                    description: "Thinks step-by-step before answering. Best for tricky exam questions, calculations, and problems that need careful logical reasoning."
                ),
            ]
        case .gemini:
            [
                AIModel(
                    id: "gemini-2.5-flash-lite",
                    displayName: "Gemini 2.5 Flash Lite",
                    subtitle: "Cheapest",
                    description: "Fastest and cheapest Gemini model. Ideal for simple tasks, quick fact checks, and high-throughput use where speed matters most."
                ),
                AIModel(
                    id: "gemini-2.5-flash",
                    displayName: "Gemini 2.5 Flash",
                    subtitle: "Balanced",
                    description: "Best price-performance balance. Handles everyday study questions, explanations, and agentic workflows well."
                ),
                AIModel(
                    id: "gemini-2.5-pro",
                    displayName: "Gemini 2.5 Pro",
                    subtitle: "Most capable 2.5",
                    description: "State-of-the-art reasoning for complex problems. Best for detailed analysis, challenging exam topics, and multi-step problem solving."
                ),
                AIModel(
                    id: "gemini-3-flash-preview",
                    displayName: "Gemini 3 Flash",
                    subtitle: "Next-gen preview",
                    description: "Latest generation model built for speed, scale, and frontier intelligence. Supports text, image, video, and audio input with 1M context."
                ),
            ]
        case .grok:
            [
                AIModel(
                    id: "grok-4-fast-reasoning",
                    displayName: "Grok 4 Fast",
                    subtitle: "Cheapest, 2M context",
                    description: "Fast reasoning model with a massive 2M token context window. Great for analysing long documents and complex reasoning at speed."
                ),
                AIModel(
                    id: "grok-3-mini",
                    displayName: "Grok 3 Mini",
                    subtitle: "Fast & affordable",
                    description: "Lightweight reasoning model for everyday tasks. Good for quick explanations and straightforward study questions."
                ),
                AIModel(
                    id: "grok-3",
                    displayName: "Grok 3",
                    subtitle: "Most capable",
                    description: "Full-size Grok model for the most demanding tasks. Best for deep analysis, detailed explanations, and challenging exam prep."
                ),
            ]
        }
    }

    var defaultModelId: String {
        availableModels.first!.id
    }

    func resolveModelId(_ modelId: String?) -> String {
        guard let modelId, availableModels.contains(where: { $0.id == modelId }) else {
            return defaultModelId
        }
        return modelId
    }
}

struct AIProviderConfig {
    let baseURL: String
    let modelName: String

    static func config(for provider: AIProviderType, modelId: String? = nil) -> AIProviderConfig {
        let resolvedModel = provider.resolveModelId(modelId)

        switch provider {
        case .openai:
            return AIProviderConfig(
                baseURL: "https://api.openai.com/v1/chat/completions",
                modelName: resolvedModel
            )
        case .gemini:
            return AIProviderConfig(
                baseURL: "https://generativelanguage.googleapis.com/v1beta/models/\(resolvedModel):generateContent",
                modelName: resolvedModel
            )
        case .grok:
            return AIProviderConfig(
                baseURL: "https://api.x.ai/v1/chat/completions",
                modelName: resolvedModel
            )
        }
    }
}
