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

    @Flag(name: .long, help: "Force pretty-printed JSON output")
    var pretty: Bool = false

    mutating func run() async throws {
        let runner = ReverseGeocodeRunner(geocodingService: CLGeocodingService())

        do {
            let parsedCoordinates = try parseCoordinates(coordinates)
            let response = try await runner.execute(
                lat: parsedCoordinates.lat,
                lon: parsedCoordinates.lon
            )
            let output = try JSONOutputFormatter.format(response, forcePretty: pretty)
            print(output)
        } catch let error as CLIError {
            StderrOutput().writeLine(error.message)
            throw ExitCode(rawValue: error.exitCode)
        } catch let error as JSONOutputFormatterError {
            switch error {
            case .invalidUTF8:
                StderrOutput().writeLine("Failed to encode JSON output as UTF-8.")
                throw ExitCode(rawValue: 2)
            }
        } catch {
            StderrOutput().writeLine("Unexpected reverse command failure: \(error.localizedDescription)")
            throw ExitCode(rawValue: 2)
        }
    }

    private func parseCoordinates(_ values: [String]) throws -> (lat: Double, lon: Double) {
        guard values.count == 2 else {
            throw CLIError.user("Provide exactly two coordinate values: <lat> <lon>.")
        }

        guard let lat = Double(values[0]) else {
            throw CLIError.user("Latitude must be a valid decimal number.")
        }

        guard let lon = Double(values[1]) else {
            throw CLIError.user("Longitude must be a valid decimal number.")
        }

        return (lat, lon)
    }
}
