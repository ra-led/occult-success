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

    func interpret(chart: NatalChart, apiKey: String, baseURL: String) async throws -> String {
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
                    """
                ),
                NatalChatMessage(
                    role: "user",
                    content: """
                    Сделай подробную расшифровку натальной карты на русском.

                    Формат:
                    1. Короткий портрет личности.
                    2. Солнце, Луна, ASC: ядро характера.
                    3. Личные планеты: мышление, любовь, действие.
                    4. Социальные и дальние планеты: амбиции и глубинные темы.
                    5. Дома и акценты.
                    6. Главные аспекты.
                    7. Практические рекомендации на 5 пунктов.

                    Карта:
                    \(chartPrompt(chart))
                    """
                )
            ]
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
        return content
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
}

private struct NatalChatMessage: Codable {
    let role: String
    let content: String
}

private struct NatalChatResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: NatalChatMessage
    }
}
