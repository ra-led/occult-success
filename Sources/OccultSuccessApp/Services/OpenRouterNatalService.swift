import Foundation

struct OpenRouterNatalService {
    static let natalModel = "openai/gpt-5.4"

    enum NatalError: LocalizedError {
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

    func interpret(chart: NatalChart, apiKey: String, baseURL: String) async throws -> NatalInterpretationReport {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NatalError.missingAPIKey
        }

        let trimmedBaseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/").union(.whitespacesAndNewlines))
        guard let url = URL(string: "\(trimmedBaseURL)/chat/completions") else {
            throw NatalError.invalidBaseURL
        }

        let requestBody = NatalChatRequest(
            model: Self.natalModel,
            messages: [
                NatalChatMessage(
                    role: "system",
                    content: """
                    Ты русскоязычный астрологический интерпретатор. Пиши уверенно, живо и понятно, но не утверждай фатальные предсказания как факт. Не давай медицинских, юридических, финансовых или опасных советов. Работай только по данным карты, которые дал пользователь.
                    Верни только валидный JSON без markdown, без вступлений, без заключительных предложений, без фраз вроде "Ниже описание", "Если хотите", "Могу подробнее".
                    """
                ),
                NatalChatMessage(
                    role: "user",
                    content: """
                    Сделай подробную расшифровку натальной карты на русском.

                    Строгий формат ответа:
                    {
                      "sections": [
                        {
                          "title": "Короткий портрет",
                          "paragraphs": ["1-2 абзаца обычного текста без markdown"],
                          "bullets": []
                        }
                      ]
                    }

                    Правила:
                    - Ровно 7 секций в таком порядке: "Короткий портрет", "Солнце, Луна, ASC", "Личные планеты", "Социальные и дальние планеты", "Дома и акценты", "Главные аспекты", "Практические рекомендации".
                    - В paragraphs только чистый текст. Не используй markdown, HTML, нумерацию, заголовки внутри текста, эмодзи.
                    - В bullets только короткие пункты без тире в начале.
                    - Секция "Практические рекомендации" должна содержать 5 bullets и пустой paragraphs.
                    - Остальные секции: 1-3 paragraphs, bullets можно оставить пустым.
                    - Не добавляй комментарии до или после JSON.

                    Карта:
                    \(chartPrompt(chart))
                    """
                )
            ],
            responseFormat: NatalResponseFormat(type: "json_object")
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("OccultSuccess iOS", forHTTPHeaderField: "X-Title")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(NatalChatResponse.self, from: data)
        guard let content = response.choices.first?.message.content, !content.isEmpty else {
            throw NatalError.emptyResponse
        }
        let json = sanitizedJSON(content)
        return try JSONDecoder().decode(NatalInterpretationReport.self, from: Data(json.utf8))
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

    private func chartPrompt(_ chart: NatalChart) -> String {
        let location = chart.location.map { "\($0.title), \($0.coordinateSummary), timezone=\($0.timeZoneIdentifier ?? "unknown")" } ?? "не указано"
        let placements = chart.placements
            .map { "- \($0.body.rawValue): \($0.formattedPosition), longitude=\(String(format: "%.2f", $0.longitude))°" }
            .joined(separator: "\n")
        let houses = chart.houses
            .map { "- \($0.formattedPosition)" }
            .joined(separator: "\n")
        let aspects = chart.aspects.prefix(18)
            .map { "- \($0.title)" }
            .joined(separator: "\n")

        return """
        Имя карты: \(chart.name)
        Место: \(location)
        Система домов: \(chart.houseSystem.rawValue)

        Положения:
        \(placements)

        Дома:
        \(houses)

        Аспекты:
        \(aspects.isEmpty ? "Мажорных аспектов с орбом до 6° нет." : aspects)
        """
    }
}

private struct NatalChatRequest: Encodable {
    let model: String
    let messages: [NatalChatMessage]
    let responseFormat: NatalResponseFormat

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case responseFormat = "response_format"
    }
}

private struct NatalResponseFormat: Encodable {
    let type: String
}

private struct NatalChatMessage: Codable {
    let role: String
    let content: String
}

struct NatalInterpretationReport: Decodable, Equatable {
    let sections: [NatalInterpretationSection]
}

struct NatalInterpretationSection: Decodable, Equatable, Identifiable {
    let title: String
    let paragraphs: [String]
    let bullets: [String]

    var id: String { title }
}

private struct NatalChatResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: NatalChatMessage
    }
}
