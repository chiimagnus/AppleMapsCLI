import CoreLocation
import Foundation

protocol GeocodingService: Sendable {
    func geocode(address: String) async throws -> [GeocodeResult]
    func reverseGeocode(coordinate: Coordinate) async throws -> [GeocodeResult]
}

enum GeocodingServiceError: Error, Sendable, Equatable {
    case invalidInput(String)
    case network(String)
    case noResults
}

actor CLGeocodingService: GeocodingService {
    private let geocoder: CLGeocoder

    init(geocoder: CLGeocoder = CLGeocoder()) {
        self.geocoder = geocoder
    }

    func geocode(address: String) async throws -> [GeocodeResult] {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAddress.isEmpty else {
            throw GeocodingServiceError.invalidInput("Address cannot be empty.")
        }

        do {
            let placemarks = try await geocoder.geocodeAddressString(trimmedAddress)
            let mapped = placemarks.compactMap(GeocodeResult.init(placemark:))
            guard !mapped.isEmpty else {
                throw GeocodingServiceError.noResults
            }
            return mapped
        } catch let error as GeocodingServiceError {
            throw error
        } catch let error as CLError {
            switch error.code {
            case .geocodeFoundNoResult:
                throw GeocodingServiceError.noResults
            case .network:
                throw GeocodingServiceError.network("Network failure while geocoding address.")
            default:
                throw GeocodingServiceError.network("Geocoding failed: \(error.localizedDescription)")
            }
        } catch {
            throw GeocodingServiceError.network("Geocoding failed: \(error.localizedDescription)")
        }
    }

    func reverseGeocode(coordinate: Coordinate) async throws -> [GeocodeResult] {
        do {
            let location = CLLocation(
                latitude: coordinate.lat,
                longitude: coordinate.lon
            )
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            let mapped = placemarks.compactMap(GeocodeResult.init(placemark:))
            guard !mapped.isEmpty else {
                throw GeocodingServiceError.noResults
            }
            return mapped
        } catch let error as GeocodingServiceError {
            throw error
        } catch let error as CLError {
            switch error.code {
            case .geocodeFoundNoResult:
                throw GeocodingServiceError.noResults
            case .network:
                throw GeocodingServiceError.network("Network failure while reverse geocoding coordinates.")
            default:
                throw GeocodingServiceError.network("Reverse geocoding failed: \(error.localizedDescription)")
            }
        } catch {
            throw GeocodingServiceError.network("Reverse geocoding failed: \(error.localizedDescription)")
        }
    }
}
