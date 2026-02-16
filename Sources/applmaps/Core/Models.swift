import CoreLocation
import Foundation
import MapKit

struct Coordinate: Sendable, Codable, Equatable {
    let lat: Double
    let lon: Double

    init(lat: Double, lon: Double) {
        self.lat = lat
        self.lon = lon
    }

    init?(string: String) {
        let parts = string
            .split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }

        guard parts.count == 2,
              let lat = Double(parts[0]),
              let lon = Double(parts[1]),
              (-90.0...90.0).contains(lat),
              (-180.0...180.0).contains(lon) else {
            return nil
        }

        self.lat = lat
        self.lon = lon
    }
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

struct BatchGeocodeResult: Sendable, Codable, Equatable {
    let query: String
    let results: [GeocodeResult]
}

struct BatchGeocodeResponse: Sendable, Codable, Equatable {
    let count: Int
    let results: [BatchGeocodeResult]
}

struct ReverseGeocodeResponse: Sendable, Codable, Equatable {
    let coordinate: Coordinate
    let results: [GeocodeResult]
}

struct Place: Sendable, Codable, Equatable {
    let name: String
    let coordinate: Coordinate
    let address: Address
    let phone: String?
    let url: String?
    let category: String?
    let timezone: String?
    let mapsUrl: String

    init(
        name: String,
        coordinate: Coordinate,
        address: Address,
        phone: String?,
        url: String?,
        category: String?,
        timezone: String?,
        mapsUrl: String
    ) {
        self.name = name
        self.coordinate = coordinate
        self.address = address
        self.phone = phone
        self.url = url
        self.category = category
        self.timezone = timezone
        self.mapsUrl = mapsUrl
    }

    init?(mapItem: MKMapItem) {
        guard let location = mapItem.placemark.location else {
            return nil
        }

        let resolvedName: String
        if let name = mapItem.name?.nilIfEmpty {
            resolvedName = name
        } else {
            resolvedName = mapItem.placemark.title?.nilIfEmpty ?? "Unnamed place"
        }

        let coordinate = Coordinate(
            lat: location.coordinate.latitude,
            lon: location.coordinate.longitude
        )

        self.init(
            name: resolvedName,
            coordinate: coordinate,
            address: Address(placemark: mapItem.placemark),
            phone: mapItem.phoneNumber,
            url: mapItem.url?.absoluteString,
            category: mapItem.pointOfInterestCategory?.rawValue,
            timezone: mapItem.placemark.timeZone?.identifier,
            mapsUrl: Place.makeMapsURL(name: resolvedName, coordinate: coordinate)
        )
    }

    private static func makeMapsURL(name: String, coordinate: Coordinate) -> String {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            ?? "location"
        return "https://maps.apple.com/?ll=\(coordinate.lat),\(coordinate.lon)&q=\(encodedName)"
    }
}

struct SearchResponse: Sendable, Codable, Equatable {
    let query: String
    let count: Int
    let results: [Place]
}

enum TransportMode: String, Sendable, Codable, Equatable, CaseIterable {
    case driving
    case walking
    case transit
    case cycling
}

struct ETAResult: Sendable, Codable, Equatable {
    let destination: String
    let coordinate: Coordinate
    let transportType: String
    let distanceM: Double
    let distanceText: String
    let travelTimeS: Double
    let travelTimeText: String
    let expectedArrival: String?
}

struct ETAResponse: Sendable, Codable, Equatable {
    let from: String
    let count: Int
    let results: [ETAResult]
}

struct RouteStep: Sendable, Codable, Equatable {
    let instruction: String
    let distanceM: Double
    let distanceText: String
}

struct Route: Sendable, Codable, Equatable {
    let name: String
    let distanceM: Double
    let distanceText: String
    let durationS: Double
    let durationText: String
    let advisoryNotices: [String]
    let steps: [RouteStep]
}

struct RouteEndpoint: Sendable, Codable, Equatable {
    let name: String
    let coordinate: Coordinate
}

struct DirectionsResponse: Sendable, Codable, Equatable {
    let origin: RouteEndpoint
    let destination: RouteEndpoint
    let transportType: String
    let routes: [Route]
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
