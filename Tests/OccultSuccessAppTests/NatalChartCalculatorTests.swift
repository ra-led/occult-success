import XCTest
@testable import OccultSuccessApp

final class NatalChartCalculatorTests: XCTestCase {
    func testCherkesskReferenceChartUsesExpectedTropicalSignsAndPlacidusCusps() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let birthDate = try XCTUnwrap(calendar.date(from: DateComponents(year: 1985, month: 10, day: 25, hour: 14, minute: 30)))
        let input = NatalChartInput(
            name: "Reference",
            birthDate: birthDate,
            birthPlace: "Черкесск",
            birthLocation: BirthLocation(
                title: "Черкесск",
                subtitle: "Россия",
                latitude: 44.2233,
                longitude: 42.0577,
                timeZoneIdentifier: "Europe/Moscow"
            ),
            houseSystem: .placidus
        )

        let chart = NatalChartCalculator().calculate(input: input)
        let signs = Dictionary(uniqueKeysWithValues: chart.placements.map { ($0.body, $0.sign) })

        XCTAssertEqual(signs[.sun], .scorpio)
        XCTAssertEqual(signs[.moon], .pisces)
        XCTAssertEqual(signs[.mercury], .scorpio)
        XCTAssertEqual(signs[.venus], .libra)
        XCTAssertEqual(signs[.mars], .virgo)
        XCTAssertEqual(chart.houseSystem, .placidus)
        XCTAssertEqual(chart.houses[0].longitude, 321.61, accuracy: 0.35)
        XCTAssertEqual(chart.houses[9].longitude, 250.00, accuracy: 0.35)
    }
}
