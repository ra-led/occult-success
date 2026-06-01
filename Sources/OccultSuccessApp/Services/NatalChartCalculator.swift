import Foundation

struct NatalChartCalculator {
    func calculate(input: NatalChartInput) -> NatalChart {
        let birthDate = normalizedBirthDate(input: input)
        let julianDay = julianDay(from: birthDate)
        let sunLongitude = sunEclipticLongitude(julianDay: julianDay)
        let moonLongitude = moonEclipticLongitude(julianDay: julianDay)
        let ascendantLongitude = ascendantEclipticLongitude(julianDay: julianDay, location: input.birthLocation)
        let midheavenLongitude = midheavenEclipticLongitude(julianDay: julianDay, location: input.birthLocation)
        let sun = ZodiacSign.from(longitude: sunLongitude)
        let moon = ZodiacSign.from(longitude: moonLongitude)
        let ascendant = ZodiacSign.from(longitude: ascendantLongitude)
        let name = input.name.isEmpty ? "Натальная карта" : input.name
        let placements = [
            NatalPlacement(bodyName: "Солнце", longitude: sunLongitude, sign: sun),
            NatalPlacement(bodyName: "Луна", longitude: moonLongitude, sign: moon),
            NatalPlacement(bodyName: "Асцендент", longitude: ascendantLongitude, sign: ascendant),
            NatalPlacement(bodyName: "MC", longitude: midheavenLongitude, sign: ZodiacSign.from(longitude: midheavenLongitude))
        ]

        return NatalChart(
            name: name,
            location: input.birthLocation,
            calculatedBirthDate: birthDate,
            sunSign: sun,
            moonSign: moon,
            ascendant: ascendant,
            ascendantDegree: ascendantLongitude.truncatingRemainder(dividingBy: 30),
            midheavenDegree: midheavenLongitude.truncatingRemainder(dividingBy: 30),
            placements: placements,
            houses: equalHouses(ascendantLongitude: ascendantLongitude),
            interpretation: interpretation(
                sun: sun,
                moon: moon,
                ascendant: ascendant,
                location: input.birthLocation
            )
        )
    }

    private func normalizedBirthDate(input: NatalChartInput) -> Date {
        let displayCalendar = Calendar(identifier: .gregorian)
        let components = displayCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: input.birthDate)
        guard let timeZoneIdentifier = input.birthLocation?.timeZoneIdentifier,
              let timeZone = TimeZone(identifier: timeZoneIdentifier) else {
            return input.birthDate
        }

        var birthCalendar = Calendar(identifier: .gregorian)
        birthCalendar.timeZone = timeZone
        return birthCalendar.date(from: components) ?? input.birthDate
    }

    private func julianDay(from date: Date) -> Double {
        date.timeIntervalSince1970 / 86_400 + 2_440_587.5
    }

    private func sunEclipticLongitude(julianDay: Double) -> Double {
        let t = (julianDay - 2_451_545.0) / 36_525
        let meanLongitude = normalize(280.46646 + 36_000.76983 * t + 0.0003032 * t * t)
        let meanAnomaly = normalize(357.52911 + 35_999.05029 * t - 0.0001537 * t * t)
        let anomalyRadians = degreesToRadians(meanAnomaly)
        let equationOfCenter =
            (1.914602 - 0.004817 * t - 0.000014 * t * t) * sin(anomalyRadians)
            + (0.019993 - 0.000101 * t) * sin(2 * anomalyRadians)
            + 0.000289 * sin(3 * anomalyRadians)
        let trueLongitude = meanLongitude + equationOfCenter
        let omega = 125.04 - 1_934.136 * t
        return normalize(trueLongitude - 0.00569 - 0.00478 * sin(degreesToRadians(omega)))
    }

    private func moonEclipticLongitude(julianDay: Double) -> Double {
        let days = julianDay - 2_451_545.0
        let meanLongitude = normalize(218.316 + 13.176396 * days)
        let moonAnomaly = normalize(134.963 + 13.064993 * days)
        let sunAnomaly = normalize(357.529 + 0.98560028 * days)
        let elongation = normalize(297.850 + 12.190749 * days)
        let argumentOfLatitude = normalize(93.272 + 13.229350 * days)

        let longitude =
            meanLongitude
            + 6.289 * sin(degreesToRadians(moonAnomaly))
            + 1.274 * sin(degreesToRadians(2 * elongation - moonAnomaly))
            + 0.658 * sin(degreesToRadians(2 * elongation))
            + 0.214 * sin(degreesToRadians(2 * moonAnomaly))
            - 0.186 * sin(degreesToRadians(sunAnomaly))
            - 0.114 * sin(degreesToRadians(2 * argumentOfLatitude))

        return normalize(longitude)
    }

    private func ascendantEclipticLongitude(julianDay: Double, location: BirthLocation?) -> Double {
        let latitude = degreesToRadians(location?.latitude ?? 0)
        let sidereal = degreesToRadians(localSiderealTime(julianDay: julianDay, longitude: location?.longitude ?? 0))
        let obliquity = degreesToRadians(meanObliquity(julianDay: julianDay))
        let y = -cos(sidereal)
        let x = sin(sidereal) * cos(obliquity) + tan(latitude) * sin(obliquity)
        return normalize(radiansToDegrees(atan2(y, x)))
    }

    private func midheavenEclipticLongitude(julianDay: Double, location: BirthLocation?) -> Double {
        let sidereal = degreesToRadians(localSiderealTime(julianDay: julianDay, longitude: location?.longitude ?? 0))
        let obliquity = degreesToRadians(meanObliquity(julianDay: julianDay))
        return normalize(radiansToDegrees(atan2(sin(sidereal), cos(sidereal) * cos(obliquity))))
    }

    private func localSiderealTime(julianDay: Double, longitude: Double) -> Double {
        let t = (julianDay - 2_451_545.0) / 36_525
        let greenwichSidereal =
            280.46061837
            + 360.98564736629 * (julianDay - 2_451_545.0)
            + 0.000387933 * t * t
            - (t * t * t) / 38_710_000
        return normalize(greenwichSidereal + longitude)
    }

    private func meanObliquity(julianDay: Double) -> Double {
        let t = (julianDay - 2_451_545.0) / 36_525
        return 23.439291111 - 0.013004167 * t - 0.000000164 * t * t + 0.000000504 * t * t * t
    }

    private func equalHouses(ascendantLongitude: Double) -> [String] {
        (0..<12).map { house in
            let cusp = normalize(ascendantLongitude + Double(house) * 30)
            let sign = ZodiacSign.from(longitude: cusp)
            let degree = cusp.truncatingRemainder(dividingBy: 30)
            return "\(house + 1) дом: \(sign.rawValue) \(String(format: "%.1f°", degree))"
        }
    }

    private func interpretation(
        sun: ZodiacSign,
        moon: ZodiacSign,
        ascendant: ZodiacSign,
        location: BirthLocation?
    ) -> String {
        let locationText: String
        if let location {
            locationText = "Место рождения учтено по координатам \(location.coordinateSummary), долготе, широте и часовому поясу \(location.timeZoneIdentifier ?? "системному")."
        } else {
            locationText = "Место рождения не выбрано, поэтому асцендент рассчитан для нулевых координат и будет менее полезен."
        }

        return "Солнце в знаке \(sun.rawValue) показывает базовую волю, Луна в знаке \(moon.rawValue) описывает эмоциональный ритм, а асцендент \(ascendant.rawValue) задаёт стиль первого впечатления. \(locationText) Расчёт детерминированный: дата рождения переводится в UTC через часовой пояс города, затем используются Julian Day, местное звёздное время и эклиптические долготы светил."
    }

    private func normalize(_ degrees: Double) -> Double {
        let value = degrees.truncatingRemainder(dividingBy: 360)
        return value >= 0 ? value : value + 360
    }

    private func degreesToRadians(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }

    private func radiansToDegrees(_ radians: Double) -> Double {
        radians * 180 / .pi
    }
}
