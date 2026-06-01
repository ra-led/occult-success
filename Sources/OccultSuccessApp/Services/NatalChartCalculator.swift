import Foundation

struct NatalChartCalculator {
    func calculate(input: NatalChartInput) -> NatalChart {
        let birthDate = normalizedBirthDate(input: input)
        let julianDay = julianDay(from: birthDate)
        let sunLongitude = sunEclipticLongitude(julianDay: julianDay)
        let moonLongitude = moonEclipticLongitude(julianDay: julianDay)
        let ascendantLongitude = ascendantEclipticLongitude(julianDay: julianDay, location: input.birthLocation)
        let midheavenLongitude = midheavenEclipticLongitude(julianDay: julianDay, location: input.birthLocation)
        let houses = houseCusps(
            system: input.houseSystem,
            julianDay: julianDay,
            location: input.birthLocation,
            ascendantLongitude: ascendantLongitude,
            midheavenLongitude: midheavenLongitude
        )

        let bodyLongitudes: [(CelestialBody, Double)] = [
            (.sun, sunLongitude),
            (.moon, moonLongitude),
            (.mercury, planetLongitude(.mercury, julianDay: julianDay, earthSunLongitude: sunLongitude)),
            (.venus, planetLongitude(.venus, julianDay: julianDay, earthSunLongitude: sunLongitude)),
            (.mars, planetLongitude(.mars, julianDay: julianDay, earthSunLongitude: sunLongitude)),
            (.jupiter, planetLongitude(.jupiter, julianDay: julianDay, earthSunLongitude: sunLongitude)),
            (.saturn, planetLongitude(.saturn, julianDay: julianDay, earthSunLongitude: sunLongitude)),
            (.uranus, planetLongitude(.uranus, julianDay: julianDay, earthSunLongitude: sunLongitude)),
            (.neptune, planetLongitude(.neptune, julianDay: julianDay, earthSunLongitude: sunLongitude)),
            (.pluto, planetLongitude(.pluto, julianDay: julianDay, earthSunLongitude: sunLongitude)),
            (.ascendant, ascendantLongitude),
            (.midheaven, midheavenLongitude)
        ]

        let placements = bodyLongitudes.map { body, longitude in
            NatalPlacement(
                body: body,
                longitude: longitude,
                sign: ZodiacSign.from(longitude: longitude),
                house: houseNumber(for: longitude, cusps: houses)
            )
        }
        let sun = ZodiacSign.from(longitude: sunLongitude)
        let moon = ZodiacSign.from(longitude: moonLongitude)
        let ascendant = ZodiacSign.from(longitude: ascendantLongitude)
        let name = input.name.isEmpty ? "Натальная карта" : input.name

        return NatalChart(
            name: name,
            location: input.birthLocation,
            calculatedBirthDate: birthDate,
            houseSystem: input.houseSystem,
            sunSign: sun,
            moonSign: moon,
            ascendant: ascendant,
            ascendantDegree: ascendantLongitude.truncatingRemainder(dividingBy: 30),
            midheavenDegree: midheavenLongitude.truncatingRemainder(dividingBy: 30),
            placements: placements,
            houses: houses,
            aspects: aspects(from: placements),
            interpretation: interpretation(
                sun: sun,
                moon: moon,
                ascendant: ascendant,
                houseSystem: input.houseSystem,
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

    private func planetLongitude(_ body: CelestialBody, julianDay: Double, earthSunLongitude: Double) -> Double {
        guard let elements = OrbitalElements.elements(for: body, daysFromJ2000: julianDay - 2_451_545.0) else {
            return earthSunLongitude
        }
        guard let sunGeocentric = OrbitalElements.elements(for: EarthBody.earth, daysFromJ2000: julianDay - 2_451_545.0) else {
            return earthSunLongitude
        }

        let planet = heliocentricPosition(elements)
        let sun = heliocentricPosition(sunGeocentric)
        let x = planet.x + sun.x
        let y = planet.y + sun.y
        return normalize(radiansToDegrees(atan2(y, x)))
    }

    private func heliocentricPosition(_ elements: OrbitalElements) -> Vector2 {
        let eccentricAnomaly = solveKepler(meanAnomaly: degreesToRadians(elements.meanAnomaly), eccentricity: elements.eccentricity)
        let xv = elements.semiMajorAxis * (cos(eccentricAnomaly) - elements.eccentricity)
        let yv = elements.semiMajorAxis * (sqrt(1 - elements.eccentricity * elements.eccentricity) * sin(eccentricAnomaly))
        let trueAnomaly = atan2(yv, xv)
        let radius = sqrt(xv * xv + yv * yv)
        let node = degreesToRadians(elements.longitudeAscendingNode)
        let inclination = degreesToRadians(elements.inclination)
        let perihelion = degreesToRadians(elements.argumentOfPerihelion)
        let angle = trueAnomaly + perihelion

        let x = radius * (cos(node) * cos(angle) - sin(node) * sin(angle) * cos(inclination))
        let y = radius * (sin(node) * cos(angle) + cos(node) * sin(angle) * cos(inclination))
        return Vector2(x: x, y: y)
    }

    private func solveKepler(meanAnomaly: Double, eccentricity: Double) -> Double {
        var eccentricAnomaly = meanAnomaly
        for _ in 0..<10 {
            let delta = (eccentricAnomaly - eccentricity * sin(eccentricAnomaly) - meanAnomaly) / (1 - eccentricity * cos(eccentricAnomaly))
            eccentricAnomaly -= delta
            if abs(delta) < 0.0000001 { break }
        }
        return eccentricAnomaly
    }

    private func ascendantEclipticLongitude(julianDay: Double, location: BirthLocation?) -> Double {
        ascendantCrossing(
            rectAscension: localSiderealTime(julianDay: julianDay, longitude: location?.longitude ?? 0) + 90,
            poleHeight: location?.latitude ?? 0,
            obliquity: meanObliquity(julianDay: julianDay)
        )
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

    private func houseCusps(
        system: HouseSystem,
        julianDay: Double,
        location: BirthLocation?,
        ascendantLongitude: Double,
        midheavenLongitude: Double
    ) -> [HouseCusp] {
        let cusps: [Double]
        switch system {
        case .wholeSign:
            let ascendantSignStart = floor(normalize(ascendantLongitude) / 30) * 30
            cusps = (0..<12).map { normalize(ascendantSignStart + Double($0) * 30) }
        case .equal:
            cusps = (0..<12).map { normalize(ascendantLongitude + Double($0) * 30) }
        case .placidus:
            cusps = placidusCusps(
                julianDay: julianDay,
                location: location,
                ascendantLongitude: ascendantLongitude,
                midheavenLongitude: midheavenLongitude
            )
        }

        return cusps.enumerated().map { index, longitude in
            HouseCusp(number: index + 1, longitude: longitude, sign: ZodiacSign.from(longitude: longitude))
        }
    }

    private func quadrantCusps(ascendantLongitude: Double, midheavenLongitude: Double) -> [Double] {
        let first = normalize(ascendantLongitude)
        let tenth = normalize(midheavenLongitude)
        let fourth = normalize(tenth + 180)
        let seventh = normalize(first + 180)
        return [
            first,
            interpolateClockwise(from: first, to: fourth, fraction: 1 / 3),
            interpolateClockwise(from: first, to: fourth, fraction: 2 / 3),
            fourth,
            interpolateClockwise(from: fourth, to: seventh, fraction: 1 / 3),
            interpolateClockwise(from: fourth, to: seventh, fraction: 2 / 3),
            seventh,
            interpolateClockwise(from: seventh, to: tenth, fraction: 1 / 3),
            interpolateClockwise(from: seventh, to: tenth, fraction: 2 / 3),
            tenth,
            interpolateClockwise(from: tenth, to: first, fraction: 1 / 3),
            interpolateClockwise(from: tenth, to: first, fraction: 2 / 3)
        ]
    }

    private func placidusCusps(
        julianDay: Double,
        location: BirthLocation?,
        ascendantLongitude: Double,
        midheavenLongitude: Double
    ) -> [Double] {
        let latitude = location?.latitude ?? 0
        let obliquity = meanObliquity(julianDay: julianDay)
        guard abs(latitude) < 90 - obliquity else {
            return quadrantCusps(ascendantLongitude: ascendantLongitude, midheavenLongitude: midheavenLongitude)
        }

        let sidereal = localSiderealTime(julianDay: julianDay, longitude: location?.longitude ?? 0)
        let helperAngle = asinDegrees(tanDegrees(latitude) * tanDegrees(obliquity))
        let firstPole = atanDegrees(sinDegrees(helperAngle / 3) / tanDegrees(obliquity))
        let secondPole = atanDegrees(sinDegrees(helperAngle * 2 / 3) / tanDegrees(obliquity))

        let cusp11 = placidusIntermediateCusp(
            rectAscension: normalize(sidereal + 30),
            initialPole: firstPole,
            divisor: 3,
            latitude: latitude,
            obliquity: obliquity
        )
        let cusp12 = placidusIntermediateCusp(
            rectAscension: normalize(sidereal + 60),
            initialPole: secondPole,
            divisor: 1.5,
            latitude: latitude,
            obliquity: obliquity
        )
        let cusp2 = placidusIntermediateCusp(
            rectAscension: normalize(sidereal + 120),
            initialPole: secondPole,
            divisor: 1.5,
            latitude: latitude,
            obliquity: obliquity
        )
        let cusp3 = placidusIntermediateCusp(
            rectAscension: normalize(sidereal + 150),
            initialPole: firstPole,
            divisor: 3,
            latitude: latitude,
            obliquity: obliquity
        )

        return [
            normalize(ascendantLongitude),
            cusp2,
            cusp3,
            normalize(midheavenLongitude + 180),
            normalize(cusp11 + 180),
            normalize(cusp12 + 180),
            normalize(ascendantLongitude + 180),
            normalize(cusp2 + 180),
            normalize(cusp3 + 180),
            normalize(midheavenLongitude),
            cusp11,
            cusp12
        ]
    }

    private func placidusIntermediateCusp(
        rectAscension: Double,
        initialPole: Double,
        divisor: Double,
        latitude: Double,
        obliquity: Double
    ) -> Double {
        var cusp = ascendantCrossing(rectAscension: rectAscension, poleHeight: initialPole, obliquity: obliquity)
        var previous = cusp

        for iteration in 0..<100 {
            let tangent = tanDegrees(asinDegrees(sinDegrees(obliquity) * sinDegrees(cusp)))
            guard abs(tangent) > 0.00000001 else { return normalize(rectAscension) }

            let poleHeight = atanDegrees(sinDegrees(asinDegrees(tanDegrees(latitude) * tangent) / divisor) / tangent)
            cusp = ascendantCrossing(rectAscension: rectAscension, poleHeight: poleHeight, obliquity: obliquity)

            if iteration > 0 && abs(signedDifference(cusp, previous)) < 0.000001 {
                return cusp
            }
            previous = cusp
        }

        return cusp
    }

    private func ascendantCrossing(rectAscension: Double, poleHeight: Double, obliquity: Double) -> Double {
        let normalizedRectAscension = normalize(rectAscension)
        let quadrant = Int(normalizedRectAscension / 90) + 1
        let sine = sinDegrees(obliquity)
        let cosine = cosDegrees(obliquity)

        let longitude: Double
        switch quadrant {
        case 1:
            longitude = ascendantCrossingInFirstQuadrant(rectAscension: normalizedRectAscension, poleHeight: poleHeight, sine: sine, cosine: cosine)
        case 2:
            longitude = 180 - ascendantCrossingInFirstQuadrant(rectAscension: 180 - normalizedRectAscension, poleHeight: -poleHeight, sine: sine, cosine: cosine)
        case 3:
            longitude = 180 + ascendantCrossingInFirstQuadrant(rectAscension: normalizedRectAscension - 180, poleHeight: -poleHeight, sine: sine, cosine: cosine)
        default:
            longitude = 360 - ascendantCrossingInFirstQuadrant(rectAscension: 360 - normalizedRectAscension, poleHeight: poleHeight, sine: sine, cosine: cosine)
        }

        return normalize(longitude)
    }

    private func ascendantCrossingInFirstQuadrant(rectAscension: Double, poleHeight: Double, sine: Double, cosine: Double) -> Double {
        let denominator = cosine * cosDegrees(rectAscension) - tanDegrees(poleHeight) * sine
        if abs(denominator) < 0.00000001 {
            return sinDegrees(rectAscension) < 0 ? 270 : 90
        }

        let longitude = atanDegrees(sinDegrees(rectAscension) / denominator)
        return longitude < 0 ? longitude + 180 : longitude
    }

    private func interpolateClockwise(from start: Double, to end: Double, fraction: Double) -> Double {
        let distance = normalize(end - start)
        return normalize(start + distance * fraction)
    }

    private func houseNumber(for longitude: Double, cusps: [HouseCusp]) -> Int {
        for index in 0..<cusps.count {
            let start = cusps[index].longitude
            let end = cusps[(index + 1) % cusps.count].longitude
            let span = normalize(end - start)
            let distance = normalize(longitude - start)
            if distance < span || abs(distance - span) < 0.0001 {
                return cusps[index].number
            }
        }
        return 1
    }

    private func aspects(from placements: [NatalPlacement]) -> [NatalAspect] {
        let bodies = placements.filter { placement in
            ![CelestialBody.ascendant, .midheaven].contains(placement.body)
        }
        var result: [NatalAspect] = []

        for firstIndex in bodies.indices {
            for secondIndex in bodies.indices where secondIndex > firstIndex {
                let distance = angularDistance(bodies[firstIndex].longitude, bodies[secondIndex].longitude)
                for kind in AspectKind.allCases {
                    let orb = abs(distance - kind.angle)
                    if orb <= 6 {
                        result.append(NatalAspect(first: bodies[firstIndex].body, second: bodies[secondIndex].body, kind: kind, orb: orb))
                    }
                }
            }
        }

        return result.sorted { $0.orb < $1.orb }
    }

    private func angularDistance(_ first: Double, _ second: Double) -> Double {
        let raw = abs(normalize(first) - normalize(second))
        return min(raw, 360 - raw)
    }

    private func interpretation(
        sun: ZodiacSign,
        moon: ZodiacSign,
        ascendant: ZodiacSign,
        houseSystem: HouseSystem,
        location: BirthLocation?
    ) -> String {
        let locationText: String
        if let location {
            locationText = "Место рождения учтено по координатам \(location.coordinateSummary), долготе, широте и часовому поясу \(location.timeZoneIdentifier ?? "системному")."
        } else {
            locationText = "Место рождения не выбрано, поэтому углы рассчитаны для нулевых координат и будут условными."
        }

        return "Солнце в знаке \(sun.rawValue), Луна в знаке \(moon.rawValue), асцендент \(ascendant.rawValue). \(locationText) Используется \(houseSystem.rawValue): \(houseSystem.description). Положения планет считаются детерминированно через Julian Day, орбитальные элементы, местное звёздное время и геоцентрическую эклиптическую долготу."
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

    private func sinDegrees(_ degrees: Double) -> Double {
        sin(degreesToRadians(degrees))
    }

    private func cosDegrees(_ degrees: Double) -> Double {
        cos(degreesToRadians(degrees))
    }

    private func tanDegrees(_ degrees: Double) -> Double {
        tan(degreesToRadians(degrees))
    }

    private func asinDegrees(_ value: Double) -> Double {
        radiansToDegrees(asin(max(-1, min(1, value))))
    }

    private func atanDegrees(_ value: Double) -> Double {
        radiansToDegrees(atan(value))
    }

    private func signedDifference(_ first: Double, _ second: Double) -> Double {
        let difference = normalize(first - second)
        return difference > 180 ? difference - 360 : difference
    }
}

private struct Vector2 {
    let x: Double
    let y: Double
}

private struct OrbitalElements {
    let longitudeAscendingNode: Double
    let inclination: Double
    let argumentOfPerihelion: Double
    let semiMajorAxis: Double
    let eccentricity: Double
    let meanAnomaly: Double

    static func elements(for body: CelestialBody, daysFromJ2000 days: Double) -> OrbitalElements? {
        switch body {
        case .mercury:
            return OrbitalElements(
                longitudeAscendingNode: 48.3313 + 3.24587e-5 * days,
                inclination: 7.0047 + 5.00e-8 * days,
                argumentOfPerihelion: 29.1241 + 1.01444e-5 * days,
                semiMajorAxis: 0.387098,
                eccentricity: 0.205635 + 5.59e-10 * days,
                meanAnomaly: 168.6562 + 4.0923344368 * days
            )
        case .venus:
            return OrbitalElements(
                longitudeAscendingNode: 76.6799 + 2.46590e-5 * days,
                inclination: 3.3946 + 2.75e-8 * days,
                argumentOfPerihelion: 54.8910 + 1.38374e-5 * days,
                semiMajorAxis: 0.723330,
                eccentricity: 0.006773 - 1.302e-9 * days,
                meanAnomaly: 48.0052 + 1.6021302244 * days
            )
        case .mars:
            return OrbitalElements(
                longitudeAscendingNode: 49.5574 + 2.11081e-5 * days,
                inclination: 1.8497 - 1.78e-8 * days,
                argumentOfPerihelion: 286.5016 + 2.92961e-5 * days,
                semiMajorAxis: 1.523688,
                eccentricity: 0.093405 + 2.516e-9 * days,
                meanAnomaly: 18.6021 + 0.5240207766 * days
            )
        case .jupiter:
            return OrbitalElements(
                longitudeAscendingNode: 100.4542 + 2.76854e-5 * days,
                inclination: 1.3030 - 1.557e-7 * days,
                argumentOfPerihelion: 273.8777 + 1.64505e-5 * days,
                semiMajorAxis: 5.20256,
                eccentricity: 0.048498 + 4.469e-9 * days,
                meanAnomaly: 19.8950 + 0.0830853001 * days
            )
        case .saturn:
            return OrbitalElements(
                longitudeAscendingNode: 113.6634 + 2.38980e-5 * days,
                inclination: 2.4886 - 1.081e-7 * days,
                argumentOfPerihelion: 339.3939 + 2.97661e-5 * days,
                semiMajorAxis: 9.55475,
                eccentricity: 0.055546 - 9.499e-9 * days,
                meanAnomaly: 316.9670 + 0.0334442282 * days
            )
        case .uranus:
            return OrbitalElements(
                longitudeAscendingNode: 74.0005 + 1.3978e-5 * days,
                inclination: 0.7733 + 1.9e-8 * days,
                argumentOfPerihelion: 96.6612 + 3.0565e-5 * days,
                semiMajorAxis: 19.18171 - 1.55e-8 * days,
                eccentricity: 0.047318 + 7.45e-9 * days,
                meanAnomaly: 142.5905 + 0.011725806 * days
            )
        case .neptune:
            return OrbitalElements(
                longitudeAscendingNode: 131.7806 + 3.0173e-5 * days,
                inclination: 1.7700 - 2.55e-7 * days,
                argumentOfPerihelion: 272.8461 - 6.027e-6 * days,
                semiMajorAxis: 30.05826 + 3.313e-8 * days,
                eccentricity: 0.008606 + 2.15e-9 * days,
                meanAnomaly: 260.2471 + 0.005995147 * days
            )
        case .pluto:
            return OrbitalElements(
                longitudeAscendingNode: 110.30347,
                inclination: 17.14175,
                argumentOfPerihelion: 113.76329,
                semiMajorAxis: 39.48168677,
                eccentricity: 0.24880766,
                meanAnomaly: 14.53 + 0.003975709 * days
            )
        case .sun, .moon, .ascendant, .midheaven:
            return nil
        }
    }

    static func elements(for body: EarthBody, daysFromJ2000 days: Double) -> OrbitalElements? {
        switch body {
        case .earth:
            return OrbitalElements(
                longitudeAscendingNode: 0,
                inclination: 0,
                argumentOfPerihelion: 282.9404 + 4.70935e-5 * days,
                semiMajorAxis: 1.000000,
                eccentricity: 0.016709 - 1.151e-9 * days,
                meanAnomaly: 356.0470 + 0.9856002585 * days
            )
        }
    }
}

private enum EarthBody {
    case earth
}
