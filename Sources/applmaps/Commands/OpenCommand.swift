import AppKit
import ArgumentParser
import Foundation

struct OpenCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "open",
        abstract: "Construct and open Apple Maps URLs."
    )

    @Option(name: .long, help: "Search query to open in Maps")
    var search: String?

    @Option(name: .long, help: "Location coordinate in 'lat,lon' format")
    var location: String?

    @Option(name: .long, help: "Directions origin query")
    var from: String?

    @Option(name: .long, help: "Directions destination query")
    var to: String?

    @Option(name: .long, help: "Directions mode: driving, walking, transit, cycling")
    var mode: String = TransportMode.driving.rawValue

    @Option(name: .long, help: "Zoom level for --location (2...21)")
    var zoom: Int?

    @Option(name: .long, help: "Comma-separated JSON fields to include in output")
    var fields: String?

    @Flag(name: .long, help: "Force pretty-printed JSON output")
    var pretty: Bool = false

    @Flag(name: .long, help: "Print command input/output JSON schema and exit")
    var jsonSchema: Bool = false

    mutating func run() async throws {
        do {
            if jsonSchema {
                let output = try CommandSchemaOutput.render(
                    command: "open",
                    pretty: pretty,
                    fields: fields
                )
                print(output)
                return
            }

            let action = try resolveAction()
            let url = try buildURL(for: action)
            let opened = await MainActor.run { NSWorkspace.shared.open(url) }

            let response = OpenResponse(
                action: action.name,
                url: url.absoluteString,
                opened: opened
            )
            let output = try JSONOutputFormatter.format(
                response,
                forcePretty: pretty,
                fields: fields
            )
            print(output)
        } catch let error as CLIError {
            StderrOutput().writeLine(error.message)
            throw ExitCode(rawValue: error.exitCode)
        } catch let error as JSONOutputFormatterError {
            switch error {
            case .invalidUTF8:
                StderrOutput().writeLine("Failed to encode JSON output as UTF-8.")
                throw ExitCode(rawValue: 2)
            case let .invalidFields(message):
                StderrOutput().writeLine(message)
                throw ExitCode(rawValue: 1)
            }
        } catch {
            StderrOutput().writeLine("Unexpected open command failure: \(error.localizedDescription)")
            throw ExitCode(rawValue: 2)
        }
    }

    private enum Action {
        case search(String)
        case location(Coordinate)
        case directions(from: String, to: String, mode: TransportMode)

        var name: String {
            switch self {
            case .search:
                return "search"
            case .location:
                return "location"
            case .directions:
                return "directions"
            }
        }
    }

    private func resolveAction() throws -> Action {
        let hasSearch = search?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let hasLocation = location?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let hasDirections = (from?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            || (to?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)

        let activeModeCount = [hasSearch, hasLocation, hasDirections]
            .filter { $0 }
            .count

        guard activeModeCount == 1 else {
            throw CLIError.user("Specify exactly one mode: --search, --location, or --from/--to.")
        }

        if let search, !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            guard location == nil, from == nil, to == nil, zoom == nil else {
                throw CLIError.user("When using --search, do not combine with location or directions options.")
            }
            return .search(search)
        }

        if let location, !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            guard search == nil, from == nil, to == nil else {
                throw CLIError.user("When using --location, do not combine with search or directions options.")
            }
            guard let coordinate = Coordinate(string: location) else {
                throw CLIError.user("Location must be in 'lat,lon' format with valid ranges.")
            }
            return .location(coordinate)
        }

        guard let from, !from.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CLIError.user("Directions mode requires --from and --to.")
        }
        guard let to, !to.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CLIError.user("Directions mode requires --from and --to.")
        }

        let parsedMode = try parseMode(mode)
        return .directions(from: from, to: to, mode: parsedMode)
    }

    private func buildURL(for action: Action) throws -> URL {
        do {
            switch action {
            case let .search(query):
                return try MapsURLBuilder.search(query: query)
            case let .location(coordinate):
                return try MapsURLBuilder.location(coordinate: coordinate, zoom: zoom)
            case let .directions(from, to, mode):
                return try MapsURLBuilder.directions(from: from, to: to, mode: mode)
            }
        } catch let error as MapsURLBuilderError {
            switch error {
            case let .invalidInput(message):
                throw CLIError.user(message)
            }
        }
    }

    private func parseMode(_ rawValue: String) throws -> TransportMode {
        let normalized = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard let mode = TransportMode(rawValue: normalized) else {
            throw CLIError.user("Mode must be one of: driving, walking, transit, cycling.")
        }
        return mode
    }
}
