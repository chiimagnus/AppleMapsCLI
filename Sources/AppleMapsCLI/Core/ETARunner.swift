import Foundation

struct ETARunner: Sendable {
    let etaService: any ETAService

    func execute(from: String, to destinations: [String], mode: TransportMode) async throws -> ETAResponse {
        let trimmedFrom = from.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFrom.isEmpty else {
            throw CLIError.user("Origin (--from) cannot be empty.")
        }

        let trimmedDestinations = destinations.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard !trimmedDestinations.isEmpty else {
            throw CLIError.user("Provide at least one destination with --to.")
        }

        guard !trimmedDestinations.contains(where: \.isEmpty) else {
            throw CLIError.user("Destination values in --to cannot be empty.")
        }

        do {
            let results = try await etaService.eta(
                from: trimmedFrom,
                to: trimmedDestinations,
                mode: mode
            )

            guard !results.isEmpty else {
                throw CLIError.noResults("No ETA results found.")
            }

            return ETAResponse(
                from: trimmedFrom,
                count: results.count,
                results: results
            )
        } catch let error as ETAServiceError {
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
            throw CLIError.network("Unexpected ETA error: \(error.localizedDescription)")
        }
    }
}
