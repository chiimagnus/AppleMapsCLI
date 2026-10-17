import Testing
@testable import AppleMapsCLI

@Suite("Directions Runner Tests")
struct DirectionsRunnerTests {
    @Test("Multistop itinerary calls each leg in order and sums chosen routes")
    func itinerary() async throws {
        let service = RecordingDirectionsService()
        let runner = DirectionsRunner(directionsService: service)
        let result = try await runner.executeItinerary(
            from: " 北京 ",
            via: ["洛阳", "芜湖", "杭州"],
            to: " 上海 ",
            mode: .driving,
            alternatives: true
        )

        #expect(result.from == "北京")
        #expect(result.via == ["洛阳", "芜湖", "杭州"])
        #expect(result.to == "上海")
        #expect(result.legs.count == 4)
        #expect(result.totalDistanceM == 288_000)
        #expect(result.totalDurationS == 12_000)
        #expect(await service.calls == [
            "北京 -> 洛阳 / driving / true",
            "洛阳 -> 芜湖 / driving / true",
            "芜湖 -> 杭州 / driving / true",
            "杭州 -> 上海 / driving / true"
        ])
    }

    @Test("Multistop itinerary validates inputs before any MapKit calls")
    func invalidItinerary() async {
        let service = RecordingDirectionsService()
        let runner = DirectionsRunner(directionsService: service)
        await #expect(throws: CLIError.user("Waypoint 2 cannot be empty.")) {
            try await runner.executeItinerary(
                from: "北京", via: ["洛阳", "  "], to: "上海",
                mode: .driving, alternatives: false
            )
        }
        #expect(await service.calls.isEmpty)
    }

    @Test("Failure of an intermediate leg stops the itinerary")
    func failingLeg() async {
        let service = RecordingDirectionsService(failAtDestination: "芜湖")
        let runner = DirectionsRunner(directionsService: service)
        await #expect(throws: CLIError.noResults("Leg 2/3: No directions found.")) {
            try await runner.executeItinerary(
                from: "北京", via: ["洛阳", "芜湖"], to: "上海",
                mode: .driving, alternatives: false
            )
        }
        #expect(await service.calls.count == 2)
    }

    @Test("Itinerary routes support other transport modes through each leg")
    func walkingLegs() async throws {
        let service = RecordingDirectionsService()
        let runner = DirectionsRunner(directionsService: service)
        let result = try await runner.executeItinerary(
            from: "A", via: ["B"], to: "C", mode: .walking, alternatives: false
        )
        #expect(result.transportType == "walking")
        #expect(await service.calls == [
            "A -> B / walking / false", "B -> C / walking / false"
        ])
    }

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

private actor RecordingDirectionsService: DirectionsService {
    let failAtDestination: String?
    private(set) var calls: [String] = []

    init(failAtDestination: String? = nil) {
        self.failAtDestination = failAtDestination
    }

    func directions(
        from: String,
        to: String,
        mode: TransportMode,
        alternatives: Bool
    ) async throws -> DirectionsResponse {
        calls.append("\(from) -> \(to) / \(mode.rawValue) / \(alternatives)")
        if to == failAtDestination {
            throw DirectionsServiceError.noResults("No directions found.")
        }
        return DirectionsResponse(
            origin: RouteEndpoint(name: from, coordinate: Fixtures.origin.coordinate),
            destination: RouteEndpoint(name: to, coordinate: Fixtures.destination.coordinate),
            transportType: mode.rawValue,
            routes: Fixtures.response.routes
        )
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
