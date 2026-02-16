import Foundation

struct SearchRunner: Sendable {
    let searchService: any SearchService

    func execute(
        query: String,
        near: Coordinate?,
        radiusMeters: Double?,
        limit: Int
    ) async throws -> SearchResponse {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            throw CLIError.user("Search query cannot be empty.")
        }

        if let radiusMeters, radiusMeters <= 0 {
            throw CLIError.user("Radius must be greater than zero when provided.")
        }

        guard limit > 0 else {
            throw CLIError.user("Limit must be greater than zero.")
        }

        do {
            let results = try await searchService.search(
                query: trimmedQuery,
                near: near,
                radiusMeters: radiusMeters,
                limit: limit
            )

            guard !results.isEmpty else {
                throw CLIError.noResults("No search results found.")
            }

            return SearchResponse(query: trimmedQuery, count: results.count, results: results)
        } catch let error as SearchServiceError {
            switch error {
            case let .invalidInput(message):
                throw CLIError.user(message)
            case let .network(message):
                throw CLIError.network(message)
            case .noResults:
                throw CLIError.noResults("No search results found.")
            }
        } catch let error as CLIError {
            throw error
        } catch {
            throw CLIError.network("Unexpected search error: \(error.localizedDescription)")
        }
    }
}
