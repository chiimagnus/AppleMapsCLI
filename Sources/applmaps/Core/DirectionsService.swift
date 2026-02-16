import Foundation

protocol DirectionsService: Sendable {
    func directions(
        from: String,
        to: String,
        mode: TransportMode,
        alternatives: Bool
    ) async throws -> DirectionsResponse
}

enum DirectionsServiceError: Error, Sendable, Equatable {
    case invalidInput(String)
    case network(String)
    case noResults(String)
}
