import Foundation

struct NatalChartCalculator {
    func calculate(input: NatalChartInput) -> NatalChart {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.month, .day, .hour, .minute], from: input.birthDate)
        let sun = sunSign(month: components.month ?? 1, day: components.day ?? 1)
        let moon = shiftedSign(from: sun, by: ((components.day ?? 1) / 2) + (components.hour ?? 0) / 6)
        let ascendant = shiftedSign(from: sun, by: ascendantOffset(input: input, components: components))
        let name = input.name.isEmpty ? "Натальная карта" : input.name

        return NatalChart(
            name: name,
            location: input.birthLocation,
            sunSign: sun,
            moonSign: moon,
            ascendant: ascendant,
            houses: houses(ascendant: ascendant),
            interpretation: interpretation(sun: sun, moon: moon, ascendant: ascendant, location: input.birthLocation)
        )
    }

    private func ascendantOffset(input: NatalChartInput, components: DateComponents) -> Int {
        let hour = Double(components.hour ?? 12)
        let minute = Double(components.minute ?? 0)
        let clockHours = hour + minute / 60

        guard let location = input.birthLocation else {
            return max(0, Int(clockHours / 2))
        }

        let timeZone = location.timeZoneIdentifier.flatMap(TimeZone.init(identifier:)) ?? .current
        let secondsFromGMT = Double(timeZone.secondsFromGMT(for: input.birthDate))
        let zoneLongitude = secondsFromGMT / 240
        let solarCorrectionHours = (location.longitude - zoneLongitude) / 15
        let localSolarHours = (clockHours + solarCorrectionHours + 24).truncatingRemainder(dividingBy: 24)
        return max(0, Int(localSolarHours / 2))
    }

    private func interpretation(sun: ZodiacSign, moon: ZodiacSign, ascendant: ZodiacSign, location: BirthLocation?) -> String {
        let locationText: String
        if let location {
            locationText = "Место рождения учтено по координатам \(location.coordinateSummary) и часовому поясу \(location.timeZoneIdentifier ?? "системному")."
        } else {
            locationText = "Место рождения не выбрано, поэтому асцендент рассчитан по времени без поправки на координаты."
        }

        return "Солнце в знаке \(sun.rawValue) показывает базовую волю, Луна в знаке \(moon.rawValue) описывает эмоциональный ритм, а асцендент \(ascendant.rawValue) задаёт стиль первого впечатления. \(locationText) Для точной астрологии нужны эфемериды и профессиональная домификация; этот MVP даёт мягкую прикладную интерпретацию."
    }

    private func sunSign(month: Int, day: Int) -> ZodiacSign {
        switch (month, day) {
        case (3, 21...31), (4, 1...19): return .aries
        case (4, 20...30), (5, 1...20): return .taurus
        case (5, 21...31), (6, 1...20): return .gemini
        case (6, 21...30), (7, 1...22): return .cancer
        case (7, 23...31), (8, 1...22): return .leo
        case (8, 23...31), (9, 1...22): return .virgo
        case (9, 23...30), (10, 1...22): return .libra
        case (10, 23...31), (11, 1...21): return .scorpio
        case (11, 22...30), (12, 1...21): return .sagittarius
        case (12, 22...31), (1, 1...19): return .capricorn
        case (1, 20...31), (2, 1...18): return .aquarius
        default: return .pisces
        }
    }

    private func shiftedSign(from sign: ZodiacSign, by offset: Int) -> ZodiacSign {
        let signs = ZodiacSign.allCases
        guard let index = signs.firstIndex(of: sign) else { return sign }
        return signs[(index + offset) % signs.count]
    }

    private func houses(ascendant: ZodiacSign) -> [String] {
        let signs = ZodiacSign.allCases
        let start = signs.firstIndex(of: ascendant) ?? 0
        return (0..<12).map { house in
            "\(house + 1) дом: \(signs[(start + house) % signs.count].rawValue)"
        }
    }
}
