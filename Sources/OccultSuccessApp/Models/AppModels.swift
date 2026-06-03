import Foundation

struct MoonDay: Identifiable, Equatable {
    let id = UUID()
    let number: Int
    let phaseName: String
    let illumination: Double
    let cycleFraction: Double
    let guidance: MoonGuidance
}

struct MoonGuidance: Equatable {
    let title: String
    let description: String
    let focus: String
    let actions: [String]
}

struct NatalChartInput: Equatable {
    var name = ""
    var birthDate = Date()
    var birthPlace = ""
    var birthLocation: BirthLocation?
    var houseSystem: HouseSystem = .placidus
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
    let calculatedBirthDate: Date
    let houseSystem: HouseSystem
    let sunSign: ZodiacSign
    let moonSign: ZodiacSign
    let ascendant: ZodiacSign
    let ascendantDegree: Double
    let midheavenDegree: Double
    let placements: [NatalPlacement]
    let houses: [HouseCusp]
    let aspects: [NatalAspect]
    let interpretation: String
}

struct NatalPlacement: Identifiable, Equatable {
    let id = UUID()
    let body: CelestialBody
    let longitude: Double
    let sign: ZodiacSign
    let house: Int

    var degreeInSign: Double {
        longitude.truncatingRemainder(dividingBy: 30)
    }

    var formattedPosition: String {
        "\(sign.rawValue) \(String(format: "%.2f°", degreeInSign)), \(house) дом"
    }
}

struct HouseCusp: Identifiable, Equatable {
    let number: Int
    let longitude: Double
    let sign: ZodiacSign

    var id: Int { number }

    var formattedPosition: String {
        "\(number) дом: \(sign.rawValue) \(String(format: "%.2f°", longitude.truncatingRemainder(dividingBy: 30)))"
    }
}

struct NatalAspect: Identifiable, Equatable {
    let id = UUID()
    let first: CelestialBody
    let second: CelestialBody
    let kind: AspectKind
    let orb: Double

    var title: String {
        "\(first.shortName)-\(second.shortName): \(kind.rawValue), орб \(String(format: "%.1f°", orb))"
    }
}

enum AspectKind: String, CaseIterable {
    case conjunction = "соединение"
    case sextile = "секстиль"
    case square = "квадрат"
    case trine = "трин"
    case opposition = "оппозиция"

    var angle: Double {
        switch self {
        case .conjunction: return 0
        case .sextile: return 60
        case .square: return 90
        case .trine: return 120
        case .opposition: return 180
        }
    }
}

enum HouseSystem: String, CaseIterable, Identifiable {
    case wholeSign = "Whole Sign"
    case equal = "Equal"
    case placidus = "Placidus"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .wholeSign:
            return "дома по целым знакам от асцендента"
        case .equal:
            return "равные дома от точного градуса асцендента"
        case .placidus:
            return "квадрантные дома Плацидуса"
        }
    }
}

enum CelestialBody: String, CaseIterable, Identifiable {
    case sun = "Солнце"
    case moon = "Луна"
    case mercury = "Меркурий"
    case venus = "Венера"
    case mars = "Марс"
    case jupiter = "Юпитер"
    case saturn = "Сатурн"
    case uranus = "Уран"
    case neptune = "Нептун"
    case pluto = "Плутон"
    case ascendant = "ASC"
    case midheaven = "MC"

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .sun: return "Солнце"
        case .moon: return "Луна"
        case .mercury: return "Меркурий"
        case .venus: return "Венера"
        case .mars: return "Марс"
        case .jupiter: return "Юпитер"
        case .saturn: return "Сатурн"
        case .uranus: return "Уран"
        case .neptune: return "Нептун"
        case .pluto: return "Плутон"
        case .ascendant: return "ASC"
        case .midheaven: return "MC"
        }
    }

    var glyph: String {
        switch self {
        case .sun: return "☉"
        case .moon: return "☽"
        case .mercury: return "☿"
        case .venus: return "♀"
        case .mars: return "♂"
        case .jupiter: return "♃"
        case .saturn: return "♄"
        case .uranus: return "♅"
        case .neptune: return "♆"
        case .pluto: return "♇"
        case .ascendant: return "A"
        case .midheaven: return "M"
        }
    }
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

    static func from(longitude: Double) -> ZodiacSign {
        let normalized = ((longitude.truncatingRemainder(dividingBy: 360)) + 360).truncatingRemainder(dividingBy: 360)
        return allCases[min(11, max(0, Int(normalized / 30)))]
    }
}

struct DreamInterpretation: Identifiable, Equatable {
    let id = UUID()
    let dream: String
    let report: DreamInterpretationReport
    let createdAt: Date
}

struct DreamInterpretationReport: Decodable, Equatable {
    let sections: [DreamInterpretationSection]
}

struct DreamInterpretationSection: Decodable, Equatable, Identifiable {
    let title: String
    let paragraphs: [String]
    let symbols: [DreamSymbol]
    let bullets: [String]

    var id: String { title }
}

struct DreamSymbol: Decodable, Equatable, Identifiable {
    let name: String
    let meaning: String

    var id: String { name }
}

struct SuccessHour: Identifiable, Equatable {
    let id = UUID()
    let startsAt: Date
    let endsAt: Date
    let locationName: String
    let timeZoneIdentifier: String
    let reason: String
    let score: Int
}
