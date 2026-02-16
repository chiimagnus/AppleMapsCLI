import CoreLocation
import Foundation

struct Coordinate: Sendable, Codable, Equatable {
    let lat: Double
    let lon: Double
}

struct Address: Sendable, Codable, Equatable {
    let street: String?
    let city: String?
    let state: String?
    let zip: String?
    let country: String?
    let isoCountry: String?
    let formatted: String

    init(
        street: String?,
        city: String?,
        state: String?,
        zip: String?,
        country: String?,
        isoCountry: String?,
        formatted: String
    ) {
        self.street = street
        self.city = city
        self.state = state
        self.zip = zip
        self.country = country
        self.isoCountry = isoCountry
        self.formatted = formatted
    }

    init(placemark: CLPlacemark) {
        street = Address.streetLine(from: placemark)
        city = placemark.locality?.nilIfEmpty
        state = placemark.administrativeArea?.nilIfEmpty
        zip = placemark.postalCode?.nilIfEmpty
        country = placemark.country?.nilIfEmpty
        isoCountry = placemark.isoCountryCode?.nilIfEmpty

        let localityLine = [city, state, zip]
            .compactMap { $0?.nilIfEmpty }
            .joined(separator: ", ")
            .nilIfEmpty

        let parts = [street, localityLine, country]
            .compactMap { $0?.nilIfEmpty }

        if !parts.isEmpty {
            formatted = parts.joined(separator: ", ")
        } else if let placemarkName = placemark.name?.nilIfEmpty {
            formatted = placemarkName
        } else {
            formatted = "Unknown address"
        }
    }

    private static func streetLine(from placemark: CLPlacemark) -> String? {
        let components = [placemark.subThoroughfare, placemark.thoroughfare]
            .compactMap { $0?.nilIfEmpty }

        guard !components.isEmpty else {
            return nil
        }

        return components.joined(separator: " ")
    }
}

struct GeocodeResult: Sendable, Codable, Equatable {
    let coordinate: Coordinate
    let address: Address
    let timezone: String?
    let areasOfInterest: [String]

    init(
        coordinate: Coordinate,
        address: Address,
        timezone: String?,
        areasOfInterest: [String]
    ) {
        self.coordinate = coordinate
        self.address = address
        self.timezone = timezone
        self.areasOfInterest = areasOfInterest
    }

    init?(placemark: CLPlacemark) {
        guard let location = placemark.location else {
            return nil
        }

        coordinate = Coordinate(
            lat: location.coordinate.latitude,
            lon: location.coordinate.longitude
        )
        address = Address(placemark: placemark)
        timezone = placemark.timeZone?.identifier
        areasOfInterest = placemark.areasOfInterest ?? []
    }
}

struct GeocodeResponse: Sendable, Codable, Equatable {
    let query: String
    let results: [GeocodeResult]
}

struct ReverseGeocodeResponse: Sendable, Codable, Equatable {
    let coordinate: Coordinate
    let results: [GeocodeResult]
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
