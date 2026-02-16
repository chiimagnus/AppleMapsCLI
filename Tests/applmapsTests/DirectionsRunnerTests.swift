import Testing
@testable import applmaps

@Suite("Directions Runner Tests")
struct DirectionsRunnerTests {
    @Test("Returns directions response for valid input")
    func success() async throws {
        let runner = DirectionsRunner(
            directionsService: MockDirectionsService(behavior: .success(Fixtures.response))
        )

        let response = try await runner.execute(
            from: "Cupertino",
            to: "San Francisco",
            mode: .driving,
            alternatives: false
        )

        #expect(response == Fixtures.response)
    }

    @Test("Empty origin maps to user error")
    func emptyFrom() async {
        let runner = DirectionsRunner(
            directionsService: MockDirectionsService(behavior: .success(Fixtures.response))
        )

        await #expect(throws: CLIError.user("Origin (--from) cannot be empty.")) {
            try await runner.execute(
                from: "   ",
                to: "San Francisco",
                mode: .driving,
                alternatives: false
            )
        }
    }

    @Test("Empty destination maps to user error")
    func emptyTo() async {
        let runner = DirectionsRunner(
            directionsService: MockDirectionsService(behavior: .success(Fixtures.response))
        )

        await #expect(throws: CLIError.user("Destination (--to) cannot be empty.")) {
            try await runner.execute(
                from: "Cupertino",
                to: "   ",
                mode: .driving,
                alternatives: false
            )
        }
    }

    @Test("Service no-results maps to semantic no-results error")
    func noResults() async {
        let runner = DirectionsRunner(
            directionsService: MockDirectionsService(
                behavior: .failure(.noResults("No directions found."))
            )
        )

        await #expect(throws: CLIError.noResults("No directions found.")) {
            try await runner.execute(
                from: "Cupertino",
                to: "San Francisco",
                mode: .driving,
                alternatives: false
            )
        }
    }

    @Test("Service network error maps to network error")
    func networkError() async {
        let runner = DirectionsRunner(
            directionsService: MockDirectionsService(
                behavior: .failure(.network("offline"))
            )
        )

        await #expect(throws: CLIError.network("offline")) {
            try await runner.execute(
                from: "Cupertino",
                to: "San Francisco",
                mode: .driving,
                alternatives: false
            )
        }
    }

    @Test("Empty routes are treated as no-results")
    func emptyRoutes() async {
        let runner = DirectionsRunner(
            directionsService: MockDirectionsService(
                behavior: .success(
                    DirectionsResponse(
                        origin: Fixtures.origin,
                        destination: Fixtures.destination,
                        transportType: "driving",
                        routes: []
                    )
                )
            )
        )

        await #expect(throws: CLIError.noResults("No directions found.")) {
            try await runner.execute(
                from: "Cupertino",
                to: "San Francisco",
                mode: .driving,
                alternatives: false
            )
        }
    }
}

private struct MockDirectionsService: DirectionsService {
    enum Behavior: Sendable {
        case success(DirectionsResponse)
        case failure(DirectionsServiceError)
    }

    let behavior: Behavior

    func directions(
        from: String,
        to: String,
        mode: TransportMode,
        alternatives: Bool
    ) async throws -> DirectionsResponse {
        switch behavior {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        }
    }
}

private enum Fixtures {
    static let origin = RouteEndpoint(
        name: "Cupertino",
        coordinate: Coordinate(lat: 37.3230, lon: -122.0322)
    )

    static let destination = RouteEndpoint(
        name: "San Francisco",
        coordinate: Coordinate(lat: 37.7749, lon: -122.4194)
    )

    static let response = DirectionsResponse(
        origin: origin,
        destination: destination,
        transportType: "driving",
        routes: [
            Route(
                name: "US-101 N",
                distanceM: 72000,
                distanceText: "72 km",
                durationS: 3000,
                durationText: "50m",
                advisoryNotices: [],
                steps: [
                    RouteStep(
                        instruction: "Head north",
                        distanceM: 500,
                        distanceText: "500 m"
                    ),
                    RouteStep(
                        instruction: "Merge onto US-101 N",
                        distanceM: 71500,
                        distanceText: "71.5 km"
                    )
                ]
            )
        ]
    )
}
