import Foundation

struct OpenRouterDreamService {
    enum DreamError: LocalizedError {
        case missingAPIKey
        case invalidBaseURL
        case emptyResponse

        var errorDescription: String? {
            switch self {
            case .missingAPIKey: return "Добавьте OpenRouter API key в настройках."
            case .invalidBaseURL: return "Проверьте OpenRouter Base URL в настройках."
            case .emptyResponse: return "OpenRouter вернул пустой ответ."
            }
        }
    }

    func interpret(dream: String, apiKey: String, baseURL: String, model: String) async throws -> String {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DreamError.missingAPIKey
        }

        let trimmedBaseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/").union(.whitespacesAndNewlines))
        guard let url = URL(string: "\(trimmedBaseURL)/chat/completions") else {
            throw DreamError.invalidBaseURL
        }

        let requestBody = ChatRequest(
            model: model.trimmingCharacters(in: .whitespacesAndNewlines),
            messages: [
                ChatMessage(role: "system", content: "Ты русскоязычный эзотерический сонник. Пиши образно, но не давай медицинских, юридических или опасных советов."),
                ChatMessage(role: "user", content: "Истолкуй сон практично и мистически. Сон: \(dream)")
            ]
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("OccultSuccess iOS", forHTTPHeaderField: "X-Title")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = response.choices.first?.message.content, !content.isEmpty else {
            throw DreamError.emptyResponse
        }
        return content
    }
}

private struct ChatRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
}

private struct ChatMessage: Codable {
    let role: String
    let content: String
}

private struct ChatResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: ChatMessage
    }
}
