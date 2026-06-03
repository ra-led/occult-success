import Foundation

struct MoonCalendarService {
    func moonDay(for date: Date) -> MoonDay {
        let synodicMonth = 29.530588853
        let referenceNewMoon = Date(timeIntervalSince1970: 947_182_440)
        let days = date.timeIntervalSince(referenceNewMoon) / 86_400
        let age = days.truncatingRemainder(dividingBy: synodicMonth)
        let normalizedAge = age >= 0 ? age : age + synodicMonth
        let cycleFraction = normalizedAge / synodicMonth
        let number = min(30, max(1, Int(floor(normalizedAge)) + 1))
        let illumination = 0.5 * (1 - cos(2 * .pi * cycleFraction))

        return MoonDay(
            number: number,
            phaseName: phaseName(age: normalizedAge, month: synodicMonth),
            illumination: illumination,
            cycleFraction: cycleFraction,
            advice: advice(for: number)
        )
    }

    private func phaseName(age: Double, month: Double) -> String {
        switch age / month {
        case 0..<0.03: return "Новолуние"
        case 0.03..<0.24: return "Растущая Луна"
        case 0.24..<0.28: return "Первая четверть"
        case 0.28..<0.47: return "Прибывающая Луна"
        case 0.47..<0.53: return "Полнолуние"
        case 0.53..<0.72: return "Убывающая Луна"
        case 0.72..<0.78: return "Последняя четверть"
        default: return "Старая Луна"
        }
    }

    private func advice(for day: Int) -> String {
        switch day {
        case 1...3: return "Лучше формулировать намерения и не форсировать события."
        case 4...7: return "Хорошее окно для переговоров, писем и первых шагов."
        case 8...14: return "Энергии достаточно для смелых решений и публичных действий."
        case 15...18: return "Проверяйте эмоции фактами, не обещайте лишнего."
        case 19...23: return "Подходит для очищения, закрытия долгов и разборов."
        default: return "Завершайте начатое, освобождайте место для нового цикла."
        }
    }
}
