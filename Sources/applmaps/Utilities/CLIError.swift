import Foundation

enum CLIError: Error, Sendable, Equatable {
    case user(String)
    case network(String)
    case noResults(String)

    var exitCode: Int32 {
        switch self {
        case .user:
            return 1
        case .network:
            return 2
        case .noResults:
            return 3
        }
    }

    var message: String {
        switch self {
        case let .user(text):
            return text
        case let .network(text):
            return text
        case let .noResults(text):
            return text
        }
    }
}
