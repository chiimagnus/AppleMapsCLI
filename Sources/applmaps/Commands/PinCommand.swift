import AppKit
import ArgumentParser
import Foundation

struct PinCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pin",
        abstract: "Drop a pin at a coordinate with an optional label."
    )

    @Argument(
        parsing: .captureForPassthrough,
        help: "Latitude and longitude in decimal degrees"
    )
    var coordinates: [String] = []

    @Option(name: .long, help: "Optional pin label")
    var label: String?

    @Flag(name: .long, help: "Force pretty-printed JSON output")
    var pretty: Bool = false

    mutating func run() async throws {
        do {
            let parsed = try Self.parseInputs(
                tokens: coordinates,
                defaultLabel: label,
                defaultPretty: pretty
            )

            let url = try MapsURLBuilder.pin(
                coordinate: parsed.coordinate,
                label: parsed.label
            )
            let opened = await MainActor.run { NSWorkspace.shared.open(url) }

            let response = OpenResponse(
                action: "pin",
                url: url.absoluteString,
                opened: opened
            )
            let output = try JSONOutputFormatter.format(response, forcePretty: parsed.pretty)
            print(output)
        } catch let error as CLIError {
            StderrOutput().writeLine(error.message)
            throw ExitCode(rawValue: error.exitCode)
        } catch let error as MapsURLBuilderError {
            switch error {
            case let .invalidInput(message):
                StderrOutput().writeLine(message)
                throw ExitCode(rawValue: 1)
            }
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
            StderrOutput().writeLine("Unexpected pin command failure: \(error.localizedDescription)")
            throw ExitCode(rawValue: 2)
        }
    }

    static func parseInputs(
        tokens: [String],
        defaultLabel: String?,
        defaultPretty: Bool
    ) throws -> (coordinate: Coordinate, label: String?, pretty: Bool) {
        var resolvedLabel = defaultLabel
        var resolvedPretty = defaultPretty
        var coordinateTokens: [String] = []

        var index = 0
        while index < tokens.count {
            let token = tokens[index]

            switch token {
            case "--label":
                guard index + 1 < tokens.count else {
                    throw CLIError.user("Flag --label requires a value.")
                }
                resolvedLabel = tokens[index + 1]
                index += 2
            case "--pretty":
                resolvedPretty = true
                index += 1
            default:
                coordinateTokens.append(token)
                index += 1
            }
        }

        guard coordinateTokens.count == 2 else {
            throw CLIError.user("Provide exactly two coordinate values: <lat> <lon>.")
        }

        guard let lat = Double(coordinateTokens[0]) else {
            throw CLIError.user("Latitude must be a valid decimal number.")
        }

        guard let lon = Double(coordinateTokens[1]) else {
            throw CLIError.user("Longitude must be a valid decimal number.")
        }

        guard (-90.0...90.0).contains(lat) else {
            throw CLIError.user("Latitude must be between -90 and 90.")
        }

        guard (-180.0...180.0).contains(lon) else {
            throw CLIError.user("Longitude must be between -180 and 180.")
        }

        return (Coordinate(lat: lat, lon: lon), resolvedLabel, resolvedPretty)
    }
}
