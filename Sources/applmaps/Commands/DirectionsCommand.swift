import ArgumentParser
import Foundation

struct DirectionsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "directions",
        abstract: "Get route directions with turn-by-turn steps."
    )

    @Option(name: .long, help: "Origin location query or coordinate in 'lat,lon' format")
    var from: String?

    @Option(name: .long, help: "Destination location query or coordinate in 'lat,lon' format")
    var to: String?

    @Option(name: .long, help: "Intermediate stop; repeat --via in driving order")
    var via: [String] = []

    @Option(name: .long, help: "Transport mode: driving, walking, transit, cycling")
    var mode: String = TransportMode.driving.rawValue

    @Flag(name: .long, help: "Request alternate routes when available")
    var alternatives: Bool = false

    @Option(name: .long, help: "Comma-separated JSON fields to include in output")
    var fields: String?

    @Flag(name: .long, help: "Force pretty-printed JSON output")
    var pretty: Bool = false

    @Flag(name: .long, help: "Print command input/output JSON schema and exit")
    var jsonSchema: Bool = false

    mutating func run() async throws {
        let runner = DirectionsRunner(directionsService: MapKitDirectionsService())

        do {
            if jsonSchema {
                let output = try CommandSchemaOutput.render(
                    command: "directions",
                    pretty: pretty,
                    fields: fields
                )
                print(output)
                return
            }

            guard let from, !from.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw CLIError.user("Directions requires --from unless using --json-schema.")
            }
            guard let to, !to.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw CLIError.user("Directions requires --to unless using --json-schema.")
            }

            let parsedMode = try parseMode(mode)
            if via.isEmpty {
                let response = try await runner.execute(
                    from: from,
                    to: to,
                    mode: parsedMode,
                    alternatives: alternatives
                )
                print(try JSONOutputFormatter.format(
                    response, forcePretty: pretty, fields: fields
                ))
            } else {
                let response = try await runner.executeItinerary(
                    from: from,
                    via: via,
                    to: to,
                    mode: parsedMode,
                    alternatives: alternatives
                )
                print(try JSONOutputFormatter.format(
                    response, forcePretty: pretty, fields: fields
                ))
            }
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
            StderrOutput().writeLine("Unexpected directions command failure: \(error.localizedDescription)")
            throw ExitCode(rawValue: 2)
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
