import Testing
@testable import applmaps

@Suite("ETA Runner Tests")
struct ETARunnerTests {
    @Test("Returns ETA response for valid input")
    func success() async throws {
        let runner = ETARunner(
            etaService: MockETAService(behavior: .success([Fixtures.result]))
        )

        let response = try await runner.execute(
            from: "San Francisco",
            to: ["Oakland"],
            mode: .driving
        )

        #expect(response.from == "San Francisco")
        #expect(response.count == 1)
        #expect(response.results == [Fixtures.result])
    }

    @Test("Empty origin maps to user error")
    func emptyFrom() async {
        let runner = ETARunner(
            etaService: MockETAService(behavior: .success([Fixtures.result]))
        )

        await #expect(throws: CLIError.user("Origin (--from) cannot be empty.")) {
            try await runner.execute(
                from: "   ",
                to: ["Oakland"],
                mode: .driving
            )
        }
    }

    @Test("Missing destinations maps to user error")
    func missingTo() async {
        let runner = ETARunner(
            etaService: MockETAService(behavior: .success([Fixtures.result]))
        )

        await #expect(throws: CLIError.user("Provide at least one destination with --to.")) {
            try await runner.execute(
                from: "San Francisco",
                to: [],
                mode: .driving
            )
        }
    }

    @Test("Empty destination value maps to user error")
    func emptyDestination() async {
        let runner = ETARunner(
            etaService: MockETAService(behavior: .success([Fixtures.result]))
        )

        await #expect(throws: CLIError.user("Destination values in --to cannot be empty.")) {
            try await runner.execute(
                from: "San Francisco",
                to: ["   "],
                mode: .driving
            )
        }
    }

    @Test("Service no-results maps to semantic no-results error")
    func noResults() async {
        let runner = ETARunner(
            etaService: MockETAService(behavior: .failure(.noResults("No ETA results found.")))
        )

        await #expect(throws: CLIError.noResults("No ETA results found.")) {
            try await runner.execute(
                from: "San Francisco",
                to: ["Oakland"],
                mode: .driving
            )
        }
    }

    @Test("Service network error maps to network error")
    func networkError() async {
        let runner = ETARunner(
            etaService: MockETAService(behavior: .failure(.network("offline")))
        )

        await #expect(throws: CLIError.network("offline")) {
            try await runner.execute(
                from: "San Francisco",
                to: ["Oakland"],
                mode: .driving
            )
        }
    }

    @Test("Empty service results are treated as no-results")
    func emptyServiceResults() async {
        let runner = ETARunner(
            etaService: MockETAService(behavior: .success([]))
        )

        await #expect(throws: CLIError.noResults("No ETA results found.")) {
            try await runner.execute(
                from: "San Francisco",
                to: ["Oakland"],
                mode: .driving
            )
        }
    }
}

private struct MockETAService: ETAService {
    enum Behavior: Sendable {
        case success([ETAResult])
        case failure(ETAServiceError)
    }

    let behavior: Behavior

    func eta(
        from: String,
        to destinations: [String],
        mode: TransportMode
    ) async throws -> [ETAResult] {
        switch behavior {
        case let .success(results):
            return results
        case let .failure(error):
            throw error
        }
    }
}

private enum Fixtures {
    static let result = ETAResult(
        destination: "Oakland",
        coordinate: Coordinate(lat: 37.8044, lon: -122.2712),
        transportType: "driving",
        distanceM: 13200,
        distanceText: "13.2 km",
        travelTimeS: 1140,
        travelTimeText: "19 min",
        expectedArrival: "2026-02-16T08:00:00Z"
    )
}
