import ArgumentParser
import Foundation

struct GeocodeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "geocode",
        abstract: "Convert an address into geographic coordinates."
    )

    @Argument(help: "Address query to geocode")
    var address: String?

    @Flag(name: .long, help: "Read addresses from stdin (one per line)")
    var stdin: Bool = false

    @Option(name: .long, help: "Comma-separated JSON fields to include in output")
    var fields: String?

    @Flag(name: .long, help: "Force pretty-printed JSON output")
    var pretty: Bool = false

    mutating func run() async throws {
        let geocodingService = CLGeocodingService()
        let runner = GeocodeRunner(geocodingService: geocodingService)
        let batchRunner = BatchGeocodeRunner(geocodingService: geocodingService)

        do {
            let response: any Encodable

            if stdin {
                guard address == nil else {
                    throw CLIError.user("Do not provide an address argument when using --stdin.")
                }
                let inputAddresses = try readStdinAddresses()
                response = try await batchRunner.execute(addresses: inputAddresses)
            } else {
                guard let address else {
                    throw CLIError.user("Provide an address argument or use --stdin.")
                }
                response = try await runner.execute(address: address)
            }

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
            StderrOutput().writeLine("Unexpected command failure: \(error.localizedDescription)")
            throw ExitCode(rawValue: 2)
        }
    }

    private func readStdinAddresses() throws -> [String] {
        let data = FileHandle.standardInput.readDataToEndOfFile()
        guard !data.isEmpty else {
            return []
        }

        guard let text = String(data: data, encoding: .utf8) else {
            throw CLIError.user("Stdin input must be valid UTF-8 text.")
        }

        return text.components(separatedBy: .newlines)
    }
}
