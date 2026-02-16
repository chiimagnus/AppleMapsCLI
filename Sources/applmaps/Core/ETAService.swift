import Foundation

protocol ETAService: Sendable {
    func eta(
        from: String,
        to destinations: [String],
        mode: TransportMode
    ) async throws -> [ETAResult]
}

enum ETAServiceError: Error, Sendable, Equatable {
    case invalidInput(String)
    case network(String)
    case noResults(String)
}
