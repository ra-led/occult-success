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
        guard let first = try await searchCities(query).first else {
            throw SearchError.notFound
        }
        return first
    }

    func searchCities(_ query: String) async throws -> [BirthLocation] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { throw SearchError.emptyQuery }

        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString(trimmedQuery)
        let locations = placemarks.compactMap { placemark -> BirthLocation? in
            guard let coordinate = placemark.location?.coordinate else { return nil }
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

        guard !locations.isEmpty else {
            throw SearchError.notFound
        }
        return Array(locations.prefix(5))
    }
}
