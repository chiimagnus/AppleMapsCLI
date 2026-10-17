import CoreLocation
import Foundation
import MapKit

protocol SearchService: Sendable {
    func search(
        query: String,
        near: Coordinate?,
        radiusMeters: Double?,
        limit: Int
    ) async throws -> [Place]
}

enum SearchServiceError: Error, Sendable, Equatable {
    case invalidInput(String)
    case network(String)
    case noResults
}

actor MapKitSearchService: SearchService {
    func search(
        query: String,
        near: Coordinate?,
        radiusMeters: Double?,
        limit: Int
    ) async throws -> [Place] {
        guard !query.isEmpty else {
            throw SearchServiceError.invalidInput("Search query cannot be empty.")
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        if let near {
            let radius = max(radiusMeters ?? 5000, 1)
            request.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: near.lat, longitude: near.lon),
                latitudinalMeters: radius * 2,
                longitudinalMeters: radius * 2
            )
        }

        do {
            let response = try await MKLocalSearch(request: request).start()
            let places = response.mapItems.compactMap(Place.init(mapItem:))
            let limited = Array(places.prefix(limit))
            guard !limited.isEmpty else {
                throw SearchServiceError.noResults
            }
            return limited
        } catch let error as SearchServiceError {
            throw error
        } catch let error as MKError {
            switch error.code {
            case .placemarkNotFound:
                throw SearchServiceError.noResults
            case .loadingThrottled:
                throw SearchServiceError.network("Search request was throttled. Please retry shortly.")
            default:
                throw SearchServiceError.network("Search failed: \(error.localizedDescription)")
            }
        } catch {
            throw SearchServiceError.network("Search failed: \(error.localizedDescription)")
        }
    }
}
