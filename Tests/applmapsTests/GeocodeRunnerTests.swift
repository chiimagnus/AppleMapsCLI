import Testing
@testable import applmaps

@Suite("Geocode Runner Tests")
struct GeocodeRunnerTests {
    @Test("Returns geocode response for valid address")
    func success() async throws {
        let runner = GeocodeRunner(
            geocodingService: MockGeocodingService(behavior: .success([Fixtures.result]))
        )

        let response = try await runner.execute(address: "1 Apple Park Way")

        #expect(response.query == "1 Apple Park Way")
        #expect(response.results == [Fixtures.result])
    }

    @Test("Empty address maps to user error")
    func emptyAddress() async {
        let runner = GeocodeRunner(
            geocodingService: MockGeocodingService(behavior: .success([Fixtures.result]))
        )

        await #expect(throws: CLIError.user("Address cannot be empty.")) {
            try await runner.execute(address: "   ")
        }
    }

    @Test("Service no-results maps to semantic no-results error")
    func noResults() async {
        let runner = GeocodeRunner(
            geocodingService: MockGeocodingService(behavior: .failure(.noResults))
        )

        await #expect(throws: CLIError.noResults("No geocoding results found.")) {
            try await runner.execute(address: "does not exist")
        }
    }

    @Test("Service network error maps to network error")
    func networkError() async {
        let runner = GeocodeRunner(
            geocodingService: MockGeocodingService(behavior: .failure(.network("offline")))
        )

        await #expect(throws: CLIError.network("offline")) {
            try await runner.execute(address: "1 Apple Park Way")
        }
    }

    @Test("Empty service results are treated as no-results")
    func emptyServiceResults() async {
        let runner = GeocodeRunner(
            geocodingService: MockGeocodingService(behavior: .success([]))
        )

        await #expect(throws: CLIError.noResults("No geocoding results found.")) {
            try await runner.execute(address: "Some Address")
        }
    }
}

private struct MockGeocodingService: GeocodingService {
    enum Behavior: Sendable {
        case success([GeocodeResult])
        case failure(GeocodingServiceError)
    }

    let behavior: Behavior

    func geocode(address: String) async throws -> [GeocodeResult] {
        switch behavior {
        case let .success(results):
            return results
        case let .failure(error):
            throw error
        }
    }
}

private enum Fixtures {
    static let result = GeocodeResult(
        coordinate: Coordinate(lat: 37.3349, lon: -122.0090),
        address: Address(
            street: "1 Apple Park Way",
            city: "Cupertino",
            state: "CA",
            zip: "95014",
            country: "United States",
            isoCountry: "US",
            formatted: "1 Apple Park Way, Cupertino, CA, 95014, United States"
        ),
        timezone: "America/Los_Angeles",
        areasOfInterest: ["Apple Park"]
    )
}
