import Foundation

struct GeocodeRunner: Sendable {
    let geocodingService: any GeocodingService

    func execute(address: String) async throws -> GeocodeResponse {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAddress.isEmpty else {
            throw CLIError.user("Address cannot be empty.")
        }

        do {
            let results = try await geocodingService.geocode(address: trimmedAddress)
            guard !results.isEmpty else {
                throw CLIError.noResults("No geocoding results found.")
            }

            return GeocodeResponse(query: trimmedAddress, results: results)
        } catch let error as GeocodingServiceError {
            switch error {
            case let .invalidInput(message):
                throw CLIError.user(message)
            case let .network(message):
                throw CLIError.network(message)
            case .noResults:
                throw CLIError.noResults("No geocoding results found.")
            }
        } catch {
            throw CLIError.network("Unexpected geocoding error: \(error.localizedDescription)")
        }
    }
}
