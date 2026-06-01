import CoreLocation
import Foundation

struct BirthLocationSearchService {
    enum SearchError: LocalizedError {
        case emptyQuery
        case notFound

        var errorDescription: String? {
            switch self {
            case .emptyQuery: return "Введите название города."
            case .notFound: return "Город не найден. Попробуйте добавить страну или регион."
            }
        }
    }

    func searchCity(_ query: String) async throws -> BirthLocation {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { throw SearchError.emptyQuery }

        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString(trimmedQuery)
        guard let placemark = placemarks.first,
              let coordinate = placemark.location?.coordinate else {
            throw SearchError.notFound
        }

        let title = [placemark.locality, placemark.administrativeArea]
            .compactMap { $0 }
            .joined(separator: ", ")
        let subtitle = [placemark.country, placemark.timeZone?.identifier]
            .compactMap { $0 }
            .joined(separator: " · ")

        return BirthLocation(
            title: title.isEmpty ? trimmedQuery : title,
            subtitle: subtitle,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            timeZoneIdentifier: placemark.timeZone?.identifier
        )
    }
}
