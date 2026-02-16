import ArgumentParser
import Foundation

struct GeocodeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "geocode",
        abstract: "Convert an address into geographic coordinates."
    )

    @Argument(help: "Address query to geocode")
    var address: String

    @Flag(name: .long, help: "Force pretty-printed JSON output")
    var pretty: Bool = false

    mutating func run() async throws {
        let runner = GeocodeRunner(geocodingService: CLGeocodingService())

        do {
            let response = try await runner.execute(address: address)
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
            StderrOutput().writeLine("Unexpected command failure: \(error.localizedDescription)")
            throw ExitCode(rawValue: 2)
        }
    }
}
