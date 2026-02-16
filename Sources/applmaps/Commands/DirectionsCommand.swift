import ArgumentParser
import Foundation

struct DirectionsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "directions",
        abstract: "Get route directions with turn-by-turn steps."
    )

    @Option(name: .long, help: "Origin location query or coordinate in 'lat,lon' format")
    var from: String

    @Option(name: .long, help: "Destination location query or coordinate in 'lat,lon' format")
    var to: String

    @Option(name: .long, help: "Transport mode: driving, walking, transit, cycling")
    var mode: String = TransportMode.driving.rawValue

    @Flag(name: .long, help: "Request alternate routes when available")
    var alternatives: Bool = false

    @Option(name: .long, help: "Comma-separated JSON fields to include in output")
    var fields: String?

    @Flag(name: .long, help: "Force pretty-printed JSON output")
    var pretty: Bool = false

    mutating func run() async throws {
        let runner = DirectionsRunner(directionsService: MapKitDirectionsService())

        do {
            let parsedMode = try parseMode(mode)
            let response = try await runner.execute(
                from: from,
                to: to,
                mode: parsedMode,
                alternatives: alternatives
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
