import Foundation

struct MoonDay: Identifiable, Equatable {
    let id = UUID()
    let number: Int
    let phaseName: String
    let illumination: Double
    let advice: String
}

struct NatalChartInput: Equatable {
    var name = ""
    var birthDate = Date()
    var birthPlace = ""
    var birthLocation: BirthLocation?
}

struct BirthLocation: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let latitude: Double
    let longitude: Double
    let timeZoneIdentifier: String?

    var coordinateSummary: String {
        String(format: "%.4f, %.4f", latitude, longitude)
    }
}

struct NatalChart: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let location: BirthLocation?
    let sunSign: ZodiacSign
    let moonSign: ZodiacSign
    let ascendant: ZodiacSign
    let houses: [String]
    let interpretation: String
}

enum ZodiacSign: String, CaseIterable, Identifiable {
    case aries = "Овен"
    case taurus = "Телец"
    case gemini = "Близнецы"
    case cancer = "Рак"
    case leo = "Лев"
    case virgo = "Дева"
    case libra = "Весы"
    case scorpio = "Скорпион"
    case sagittarius = "Стрелец"
    case capricorn = "Козерог"
    case aquarius = "Водолей"
    case pisces = "Рыбы"

    var id: String { rawValue }
}

struct DreamInterpretation: Identifiable, Equatable {
    let id = UUID()
    let dream: String
    let text: String
    let createdAt: Date
}

struct Ritual: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var subtitle: String
    var accent: String
    var steps: [RitualStep]

    var progress: Double {
        guard !steps.isEmpty else { return 0 }
        return Double(steps.filter(\.isDone).count) / Double(steps.count)
    }

    static let seed: [Ritual] = [
        Ritual(
            title: "Ритуал ясного намерения",
            subtitle: "7 минут перед важным действием",
            accent: "sparkles",
            steps: [
                RitualStep(title: "Сформулировать одно действие на сегодня"),
                RitualStep(title: "Записать желаемый результат в настоящем времени"),
                RitualStep(title: "Поставить таймер на 7 минут тишины"),
                RitualStep(title: "Сделать первый практический шаг сразу после таймера")
            ]
        ),
        Ritual(
            title: "Денежный фокус",
            subtitle: "Короткая практика для сделки или продажи",
            accent: "banknote",
            steps: [
                RitualStep(title: "Открыть список текущих возможностей"),
                RitualStep(title: "Выбрать одну самую близкую к деньгам"),
                RitualStep(title: "Написать сообщение или сделать звонок"),
                RitualStep(title: "Отметить результат без оценки")
            ]
        )
    ]
}

struct RitualStep: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var isDone = false
}

struct SuccessHour: Identifiable, Equatable {
    let id = UUID()
    let startsAt: Date
    let endsAt: Date
}
