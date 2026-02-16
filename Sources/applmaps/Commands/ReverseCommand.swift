import ArgumentParser
import Foundation

struct ReverseCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "reverse",
        abstract: "Convert latitude and longitude into a formatted address."
    )

    @Argument(
        parsing: .captureForPassthrough,
        help: "Latitude and longitude in decimal degrees"
    )
    var coordinates: [String] = []

    @Option(name: .long, help: "Comma-separated JSON fields to include in output")
    var fields: String?

    @Flag(name: .long, help: "Force pretty-printed JSON output")
    var pretty: Bool = false

    mutating func run() async throws {
        let runner = ReverseGeocodeRunner(geocodingService: CLGeocodingService())

        do {
            let parsed = try Self.parseInputs(
                tokens: coordinates,
                defaultPretty: pretty,
                defaultFields: fields
            )
            let response = try await runner.execute(
                lat: parsed.coordinate.lat,
                lon: parsed.coordinate.lon
            )
            let output = try JSONOutputFormatter.format(
                response,
                forcePretty: parsed.pretty,
                fields: parsed.fields
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
            StderrOutput().writeLine("Unexpected reverse command failure: \(error.localizedDescription)")
            throw ExitCode(rawValue: 2)
        }
    }

    static func parseInputs(
        tokens: [String],
        defaultPretty: Bool,
        defaultFields: String?
    ) throws -> (coordinate: Coordinate, pretty: Bool, fields: String?) {
        var resolvedPretty = defaultPretty
        var resolvedFields = defaultFields
        var coordinateTokens: [String] = []

        var index = 0
        while index < tokens.count {
            let token = tokens[index]
            switch token {
            case "--pretty":
                resolvedPretty = true
                index += 1
            case "--fields":
                guard index + 1 < tokens.count else {
                    throw CLIError.user("Flag --fields requires a value.")
                }
                resolvedFields = tokens[index + 1]
                index += 2
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

        return (Coordinate(lat: lat, lon: lon), resolvedPretty, resolvedFields)
    }
}
