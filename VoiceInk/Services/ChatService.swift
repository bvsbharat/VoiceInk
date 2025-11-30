import Foundation
import os

class ChatService {
    private let logger = Logger(subsystem: "com.bharatkumar.voiceink", category: "ChatService")
    
    func sendMessage(messages: [ChatMessage], provider: AIProvider, modelId: String) async throws -> String {
        let apiKey = getAPIKey(for: provider)
        guard !apiKey.isEmpty else {
            throw ChatError.missingAPIKey
        }
        
        let endpoint = URL(string: provider.baseURL)!
        let requestBody = createRequestBody(messages: messages, provider: provider, modelId: modelId)
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Set authorization header based on provider
        if provider == .anthropic {
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        } else {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            logger.error("API request failed with status code: \(httpResponse.statusCode)")
            if let errorBody = String(data: data, encoding: .utf8) {
                logger.error("Error response: \(errorBody)")
            }
            throw ChatError.apiError(statusCode: httpResponse.statusCode)
        }
        
        return try parseResponse(data: data, provider: provider)
    }
    
    private func getAPIKey(for provider: AIProvider) -> String {
        let key: String
        switch provider {
        case .openAI:
            key = "OpenAIAPIKey"
        case .anthropic:
            key = "AnthropicAPIKey"
        case .groq:
            key = "GroqAPIKey"
        case .gemini:
            key = "GeminiAPIKey"
        case .cerebras:
            key = "CerebrasAPIKey"
        case .mistral:
            key = "MistralAPIKey"
        case .openRouter:
            key = "OpenRouterAPIKey"
        default:
            return ""
        }
        return UserDefaults.standard.string(forKey: key) ?? ""
    }
    
    private func createRequestBody(messages: [ChatMessage], provider: AIProvider, modelId: String) -> [String: Any] {
        let messageArray = messages.map { message in
            return [
                "role": message.role.rawValue,
                "content": message.content
            ]
        }
        
        let body: [String: Any] = [
            "model": modelId,
            "messages": messageArray,
            "temperature": 0.7,
            "max_tokens": 4096
        ]
        
        return body
    }
    
    private func parseResponse(data: Data, provider: AIProvider) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ChatError.invalidResponse
        }
        
        // Anthropic format
        if provider == .anthropic {
            if let content = json["content"] as? [[String: Any]],
               let firstContent = content.first,
               let text = firstContent["text"] as? String {
                return text
            }
        }
        
        // OpenAI/Groq/Cerebras/etc format
        if let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }
        
        throw ChatError.invalidResponse
    }
}

enum ChatError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case apiError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key is missing. Please configure your API key in AI Models settings."
        case .invalidResponse:
            return "Invalid response from AI service."
        case .apiError(let code):
            return "API request failed with status code \(code)."
        }
    }
}
