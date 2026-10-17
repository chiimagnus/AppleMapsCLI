import Testing
@testable import AppleMapsCLI

@Suite("Reverse Geocode Runner Tests")
struct ReverseGeocodeRunnerTests {
    @Test("Returns reverse geocode response for valid coordinates")
    func success() async throws {
        let runner = ReverseGeocodeRunner(
            geocodingService: MockReverseGeocodingService(behavior: .success([Fixtures.result]))
        )

        let response = try await runner.execute(lat: 37.3349, lon: -122.0090)

        #expect(response.coordinate == Coordinate(lat: 37.3349, lon: -122.0090))
        #expect(response.results == [Fixtures.result])
    }

    @Test("Latitude outside valid range maps to user error")
    func invalidLatitude() async {
        let runner = ReverseGeocodeRunner(
            geocodingService: MockReverseGeocodingService(behavior: .success([Fixtures.result]))
        )

        await #expect(throws: CLIError.user("Latitude must be between -90 and 90.")) {
            try await runner.execute(lat: 91, lon: -122.0090)
        }
    }

    @Test("Longitude outside valid range maps to user error")
    func invalidLongitude() async {
        let runner = ReverseGeocodeRunner(
            geocodingService: MockReverseGeocodingService(behavior: .success([Fixtures.result]))
        )

        await #expect(throws: CLIError.user("Longitude must be between -180 and 180.")) {
            try await runner.execute(lat: 37.3349, lon: 181)
        }
    }

    @Test("Service no-results maps to semantic no-results error")
    func noResults() async {
        let runner = ReverseGeocodeRunner(
            geocodingService: MockReverseGeocodingService(behavior: .failure(.noResults))
        )

        await #expect(throws: CLIError.noResults("No reverse geocoding results found.")) {
            try await runner.execute(lat: 37.3349, lon: -122.0090)
        }
    }

    @Test("Service network error maps to network error")
    func networkError() async {
        let runner = ReverseGeocodeRunner(
            geocodingService: MockReverseGeocodingService(behavior: .failure(.network("offline")))
        )

        await #expect(throws: CLIError.network("offline")) {
            try await runner.execute(lat: 37.3349, lon: -122.0090)
        }
    }

    @Test("Empty service results are treated as no-results")
    func emptyServiceResults() async {
        let runner = ReverseGeocodeRunner(
            geocodingService: MockReverseGeocodingService(behavior: .success([]))
        )

        await #expect(throws: CLIError.noResults("No reverse geocoding results found.")) {
            try await runner.execute(lat: 37.3349, lon: -122.0090)
        }
    }
}

private struct MockReverseGeocodingService: GeocodingService {
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

    func reverseGeocode(coordinate: Coordinate) async throws -> [GeocodeResult] {
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
