import Foundation

struct ReverseGeocodeRunner: Sendable {
    let geocodingService: any GeocodingService

    func execute(lat: Double, lon: Double) async throws -> ReverseGeocodeResponse {
        guard (-90.0...90.0).contains(lat) else {
            throw CLIError.user("Latitude must be between -90 and 90.")
        }

        guard (-180.0...180.0).contains(lon) else {
            throw CLIError.user("Longitude must be between -180 and 180.")
        }

        let coordinate = Coordinate(lat: lat, lon: lon)

        do {
            let results = try await geocodingService.reverseGeocode(coordinate: coordinate)
            guard !results.isEmpty else {
                throw CLIError.noResults("No reverse geocoding results found.")
            }

            return ReverseGeocodeResponse(coordinate: coordinate, results: results)
        } catch let error as GeocodingServiceError {
            switch error {
            case let .invalidInput(message):
                throw CLIError.user(message)
            case let .network(message):
                throw CLIError.network(message)
            case .noResults:
                throw CLIError.noResults("No reverse geocoding results found.")
            }
        } catch let error as CLIError {
            throw error
        } catch {
            throw CLIError.network("Unexpected reverse geocoding error: \(error.localizedDescription)")
        }
    }
}
