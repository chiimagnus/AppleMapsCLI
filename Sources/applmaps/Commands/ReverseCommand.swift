import ArgumentParser
import Foundation

struct ReverseCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "reverse",
        abstract: "Convert latitude and longitude into a formatted address."
    )

    @Argument(help: "Latitude in decimal degrees")
    var lat: Double

    @Argument(help: "Longitude in decimal degrees")
    var lon: Double

    @Flag(name: .long, help: "Force pretty-printed JSON output")
    var pretty: Bool = false

    mutating func run() async throws {
        let runner = ReverseGeocodeRunner(geocodingService: CLGeocodingService())

        do {
            let response = try await runner.execute(lat: lat, lon: lon)
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
}
