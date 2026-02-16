import Testing
@testable import applmaps

@Suite("Search Completion Runner Tests")
struct SearchCompletionRunnerTests {
    @Test("Returns completion response for valid query")
    func success() async throws {
        let runner = SearchCompletionRunner(
            searchCompletionService: MockSearchCompletionService(
                behavior: .success([Fixtures.suggestion])
            )
        )

        let response = try await runner.execute(
            query: "star",
            limit: 5
        )

        #expect(response.query == "star")
        #expect(response.count == 1)
        #expect(response.results == [Fixtures.suggestion])
    }

    @Test("Empty query maps to user error")
    func emptyQuery() async {
        let runner = SearchCompletionRunner(
            searchCompletionService: MockSearchCompletionService(
                behavior: .success([Fixtures.suggestion])
            )
        )

        await #expect(throws: CLIError.user("Search query cannot be empty.")) {
            try await runner.execute(
                query: "   ",
                limit: 5
            )
        }
    }

    @Test("Non-positive limit maps to user error")
    func invalidLimit() async {
        let runner = SearchCompletionRunner(
            searchCompletionService: MockSearchCompletionService(
                behavior: .success([Fixtures.suggestion])
            )
        )

        await #expect(throws: CLIError.user("Limit must be greater than zero.")) {
            try await runner.execute(
                query: "star",
                limit: 0
            )
        }
    }

    @Test("Service no-results maps to semantic no-results error")
    func noResults() async {
        let runner = SearchCompletionRunner(
            searchCompletionService: MockSearchCompletionService(
                behavior: .failure(.noResults)
            )
        )

        await #expect(throws: CLIError.noResults("No autocomplete suggestions found.")) {
            try await runner.execute(
                query: "nomatch",
                limit: 5
            )
        }
    }

    @Test("Service network error maps to network error")
    func networkError() async {
        let runner = SearchCompletionRunner(
            searchCompletionService: MockSearchCompletionService(
                behavior: .failure(.network("offline"))
            )
        )

        await #expect(throws: CLIError.network("offline")) {
            try await runner.execute(
                query: "star",
                limit: 5
            )
        }
    }

    @Test("Empty service results are treated as no-results")
    func emptyServiceResults() async {
        let runner = SearchCompletionRunner(
            searchCompletionService: MockSearchCompletionService(
                behavior: .success([])
            )
        )

        await #expect(throws: CLIError.noResults("No autocomplete suggestions found.")) {
            try await runner.execute(
                query: "star",
                limit: 5
            )
        }
    }
}

private struct MockSearchCompletionService: SearchCompletionService {
    enum Behavior: Sendable {
        case success([SearchCompletion])
        case failure(SearchCompletionServiceError)
    }

    let behavior: Behavior

    func complete(query: String, limit: Int) async throws -> [SearchCompletion] {
        switch behavior {
        case let .success(results):
            return results
        case let .failure(error):
            throw error
        }
    }
}

private enum Fixtures {
    static let suggestion = SearchCompletion(
        title: "Starbucks",
        subtitle: "Cupertino, CA, United States",
        display: "Starbucks, Cupertino, CA, United States"
    )
}
