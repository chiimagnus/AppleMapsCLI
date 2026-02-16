import Foundation

struct SearchCompletionRunner: Sendable {
    let searchCompletionService: any SearchCompletionService

    func execute(
        query: String,
        limit: Int
    ) async throws -> SearchCompletionResponse {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            throw CLIError.user("Search query cannot be empty.")
        }

        guard limit > 0 else {
            throw CLIError.user("Limit must be greater than zero.")
        }

        do {
            let results = try await searchCompletionService.complete(
                query: trimmedQuery,
                limit: limit
            )

            guard !results.isEmpty else {
                throw CLIError.noResults("No autocomplete suggestions found.")
            }

            return SearchCompletionResponse(
                query: trimmedQuery,
                count: results.count,
                results: results
            )
        } catch let error as SearchCompletionServiceError {
            switch error {
            case let .invalidInput(message):
                throw CLIError.user(message)
            case let .network(message):
                throw CLIError.network(message)
            case .noResults:
                throw CLIError.noResults("No autocomplete suggestions found.")
            }
        } catch let error as CLIError {
            throw error
        } catch {
            throw CLIError.network("Unexpected autocomplete error: \(error.localizedDescription)")
        }
    }
}
