import Foundation

struct DirectionsRunner: Sendable {
    let directionsService: any DirectionsService

    func execute(
        from: String,
        to: String,
        mode: TransportMode,
        alternatives: Bool
    ) async throws -> DirectionsResponse {
        let trimmedFrom = from.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFrom.isEmpty else {
            throw CLIError.user("Origin (--from) cannot be empty.")
        }

        let trimmedTo = to.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTo.isEmpty else {
            throw CLIError.user("Destination (--to) cannot be empty.")
        }

        do {
            let response = try await directionsService.directions(
                from: trimmedFrom,
                to: trimmedTo,
                mode: mode,
                alternatives: alternatives
            )

            guard !response.routes.isEmpty else {
                throw CLIError.noResults("No directions found.")
            }

            return response
        } catch let error as DirectionsServiceError {
            switch error {
            case let .invalidInput(message):
                throw CLIError.user(message)
            case let .network(message):
                throw CLIError.network(message)
            case let .noResults(message):
                throw CLIError.noResults(message)
            }
        } catch let error as CLIError {
            throw error
        } catch {
            throw CLIError.network("Unexpected directions error: \(error.localizedDescription)")
        }
    }
}
