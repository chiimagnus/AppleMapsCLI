import Testing
@testable import AppleMapsCLI

@Suite("Search Runner Tests")
struct SearchRunnerTests {
    @Test("Returns search response for valid query")
    func success() async throws {
        let runner = SearchRunner(
            searchService: MockSearchService(behavior: .success([Fixtures.place]))
        )

        let response = try await runner.execute(
            query: "restaurants",
            near: Coordinate(lat: 40.71, lon: -74.00),
            radiusMeters: 500,
            limit: 5
        )

        #expect(response.query == "restaurants")
        #expect(response.count == 1)
        #expect(response.results == [Fixtures.place])
    }

    @Test("Empty query maps to user error")
    func emptyQuery() async {
        let runner = SearchRunner(
            searchService: MockSearchService(behavior: .success([Fixtures.place]))
        )

        await #expect(throws: CLIError.user("Search query cannot be empty.")) {
            try await runner.execute(
                query: "   ",
                near: nil,
                radiusMeters: nil,
                limit: 5
            )
        }
    }

    @Test("Non-positive limit maps to user error")
    func invalidLimit() async {
        let runner = SearchRunner(
            searchService: MockSearchService(behavior: .success([Fixtures.place]))
        )

        await #expect(throws: CLIError.user("Limit must be greater than zero.")) {
            try await runner.execute(
                query: "coffee",
                near: nil,
                radiusMeters: nil,
                limit: 0
            )
        }
    }

    @Test("Non-positive radius maps to user error")
    func invalidRadius() async {
        let runner = SearchRunner(
            searchService: MockSearchService(behavior: .success([Fixtures.place]))
        )

        await #expect(throws: CLIError.user("Radius must be greater than zero when provided.")) {
            try await runner.execute(
                query: "coffee",
                near: Coordinate(lat: 37.78, lon: -122.41),
                radiusMeters: 0,
                limit: 5
            )
        }
    }

    @Test("Service no-results maps to semantic no-results error")
    func noResults() async {
        let runner = SearchRunner(
            searchService: MockSearchService(behavior: .failure(.noResults))
        )

        await #expect(throws: CLIError.noResults("No search results found.")) {
            try await runner.execute(
                query: "unknown",
                near: nil,
                radiusMeters: nil,
                limit: 5
            )
        }
    }

    @Test("Service network error maps to network error")
    func networkError() async {
        let runner = SearchRunner(
            searchService: MockSearchService(behavior: .failure(.network("offline")))
        )

        await #expect(throws: CLIError.network("offline")) {
            try await runner.execute(
                query: "coffee",
                near: nil,
                radiusMeters: nil,
                limit: 5
            )
        }
    }

    @Test("Empty service results are treated as no-results")
    func emptyServiceResults() async {
        let runner = SearchRunner(
            searchService: MockSearchService(behavior: .success([]))
        )

        await #expect(throws: CLIError.noResults("No search results found.")) {
            try await runner.execute(
                query: "coffee",
                near: nil,
                radiusMeters: nil,
                limit: 5
            )
        }
    }
}

private struct MockSearchService: SearchService {
    enum Behavior: Sendable {
        case success([Place])
        case failure(SearchServiceError)
    }

    let behavior: Behavior

    func search(
        query: String,
        near: Coordinate?,
        radiusMeters: Double?,
        limit: Int
    ) async throws -> [Place] {
        switch behavior {
        case let .success(results):
            return results
        case let .failure(error):
            throw error
        }
    }
}

private enum Fixtures {
    static let place = Place(
        name: "Example Cafe",
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
        phone: "+1-408-000-0000",
        url: "https://example.com",
        category: "restaurant",
        timezone: "America/Los_Angeles",
        mapsUrl: "https://maps.apple.com/?ll=37.3349,-122.0090&q=Example%20Cafe"
    )
}
