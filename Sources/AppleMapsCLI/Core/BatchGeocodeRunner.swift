import Foundation

struct BatchGeocodeRunner: Sendable {
    let geocodingService: any GeocodingService

    func execute(addresses: [String]) async throws -> BatchGeocodeResponse {
        let trimmedAddresses = addresses
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !trimmedAddresses.isEmpty else {
            throw CLIError.user("No non-empty addresses were provided.")
        }

        let runner = GeocodeRunner(geocodingService: geocodingService)
        var results: [BatchGeocodeResult] = []
        results.reserveCapacity(trimmedAddresses.count)

        for address in trimmedAddresses {
            let response = try await runner.execute(address: address)
            results.append(
                BatchGeocodeResult(
                    query: response.query,
                    results: response.results
                )
            )
        }

        return BatchGeocodeResponse(
            count: results.count,
            results: results
        )
    }
}
