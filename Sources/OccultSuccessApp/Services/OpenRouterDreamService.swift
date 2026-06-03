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

    func interpret(dream: String, apiKey: String, baseURL: String, model: String) async throws -> DreamInterpretationReport {
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
                ChatMessage(
                    role: "system",
                    content: """
                    Ты русскоязычный эзотерический сонник. Пиши образно, спокойно и практично. Не давай медицинских, юридических, финансовых или опасных советов. Не утверждай мистические выводы как факт.
                    Верни только валидный JSON без markdown, без HTML, без вступлений, без заключительных предложений, без фраз вроде "Ниже описание", "Если хотите", "Могу подробнее".
                    """
                ),
                ChatMessage(
                    role: "user",
                    content: """
                    Истолкуй сон практично и мистически.

                    Строгий формат ответа:
                    {
                      "sections": [
                        {
                          "title": "Главный образ",
                          "paragraphs": ["1-2 абзаца обычного текста без markdown"],
                          "symbols": [],
                          "bullets": []
                        }
                      ]
                    }

                    Правила:
                    - Ровно 5 секций в таком порядке: "Главный образ", "Символы сна", "Эмоциональный слой", "Знак для ближайших дней", "Что сделать".
                    - В paragraphs только чистый текст. Не используй markdown, HTML, нумерацию, заголовки внутри текста, эмодзи.
                    - Секция "Символы сна" должна содержать 3-6 symbols и пустые paragraphs/bullets. Каждый symbol: {"name":"короткое название", "meaning":"1 предложение смысла"}.
                    - Секция "Что сделать" должна содержать 4 bullets и пустые paragraphs/symbols.
                    - Остальные секции: 1-2 paragraphs, symbols и bullets пустые.
                    - В bullets только короткие практические пункты без тире в начале.
                    - Не добавляй комментарии до или после JSON.

                    Сон:
                    \(dream)
                    """
                )
            ],
            responseFormat: ChatResponseFormat(type: "json_object")
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
        let json = sanitizedJSON(content)
        return try JSONDecoder().decode(DreamInterpretationReport.self, from: Data(json.utf8))
    }

    private func sanitizedJSON(_ content: String) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("```") {
            return trimmed
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```JSON", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return trimmed
    }
}

private struct ChatRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let responseFormat: ChatResponseFormat

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case responseFormat = "response_format"
    }
}

private struct ChatResponseFormat: Encodable {
    let type: String
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
