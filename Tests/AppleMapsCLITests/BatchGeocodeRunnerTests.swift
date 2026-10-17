import Testing
@testable import AppleMapsCLI

@Suite("Batch Geocode Runner Tests")
struct BatchGeocodeRunnerTests {
    @Test("Processes addresses sequentially and preserves order")
    func sequentialProcessing() async throws {
        let service = MockBatchGeocodingService(
            stubbed: [
                "One Infinite Loop": [Fixtures.resultOne],
                "1 Apple Park Way": [Fixtures.resultTwo]
            ]
        )
        let runner = BatchGeocodeRunner(geocodingService: service)

        let response = try await runner.execute(
            addresses: ["One Infinite Loop", "1 Apple Park Way"]
        )

        #expect(response.count == 2)
        #expect(response.results.map(\.query) == ["One Infinite Loop", "1 Apple Park Way"])

        let calls = await service.calls()
        #expect(calls == ["One Infinite Loop", "1 Apple Park Way"])
    }

    @Test("Skips empty lines and trims whitespace")
    func trimsAndSkipsEmpty() async throws {
        let service = MockBatchGeocodingService(
            stubbed: [
                "1 Apple Park Way": [Fixtures.resultTwo]
            ]
        )
        let runner = BatchGeocodeRunner(geocodingService: service)

        let response = try await runner.execute(
            addresses: ["   ", " 1 Apple Park Way ", ""]
        )

        #expect(response.count == 1)
        #expect(response.results.map(\.query) == ["1 Apple Park Way"])
    }

    @Test("All-empty input maps to user error")
    func emptyInput() async {
        let service = MockBatchGeocodingService(stubbed: [:])
        let runner = BatchGeocodeRunner(geocodingService: service)

        await #expect(throws: CLIError.user("No non-empty addresses were provided.")) {
            try await runner.execute(addresses: ["", "  "])
        }
    }

    @Test("Service network errors map to network error")
    func networkError() async {
        let service = MockBatchGeocodingService(
            stubbed: [:],
            failures: ["1 Apple Park Way": .network("offline")]
        )
        let runner = BatchGeocodeRunner(geocodingService: service)

        await #expect(throws: CLIError.network("offline")) {
            try await runner.execute(addresses: ["1 Apple Park Way"])
        }
    }
}

private actor MockBatchGeocodingService: GeocodingService {
    let stubbed: [String: [GeocodeResult]]
    let failures: [String: GeocodingServiceError]
    private var geocodeCalls: [String] = []

    init(
        stubbed: [String: [GeocodeResult]],
        failures: [String: GeocodingServiceError] = [:]
    ) {
        self.stubbed = stubbed
        self.failures = failures
    }

    func geocode(address: String) async throws -> [GeocodeResult] {
        geocodeCalls.append(address)

        if let failure = failures[address] {
            throw failure
        }
        if let result = stubbed[address] {
            return result
        }
        return []
    }

    func reverseGeocode(coordinate: Coordinate) async throws -> [GeocodeResult] {
        []
    }

    func calls() -> [String] {
        geocodeCalls
    }
}

private enum Fixtures {
    static let resultOne = GeocodeResult(
        coordinate: Coordinate(lat: 37.3318, lon: -122.0312),
        address: Address(
            street: "1 Infinite Loop",
            city: "Cupertino",
            state: "CA",
            zip: "95014",
            country: "United States",
            isoCountry: "US",
            formatted: "1 Infinite Loop, Cupertino, CA, 95014, United States"
        ),
        timezone: "America/Los_Angeles",
        areasOfInterest: ["Apple Campus"]
    )

    static let resultTwo = GeocodeResult(
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
