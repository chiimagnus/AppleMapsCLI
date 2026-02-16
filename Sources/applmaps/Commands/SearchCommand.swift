import ArgumentParser
import Foundation

struct SearchCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search for places and points of interest."
    )

    @Argument(help: "Natural-language search query")
    var query: String?

    @Option(name: .long, help: "Bias results around a coordinate in 'lat,lon' format")
    var near: String?

    @Option(name: .long, help: "Search radius in meters (used with --near)")
    var radius: Double?

    @Option(name: .long, help: "Maximum number of results to return")
    var limit: Int = 10

    @Option(name: .long, help: "Comma-separated JSON fields to include in output")
    var fields: String?

    @Flag(name: .long, help: "Force pretty-printed JSON output")
    var pretty: Bool = false

    @Flag(name: .long, help: "Print command input/output JSON schema and exit")
    var jsonSchema: Bool = false

    mutating func run() async throws {
        let runner = SearchRunner(searchService: MapKitSearchService())

        do {
            if jsonSchema {
                let output = try CommandSchemaOutput.render(
                    command: "search",
                    pretty: pretty,
                    fields: fields
                )
                print(output)
                return
            }

            guard let query else {
                throw CLIError.user("Provide a search query argument or use --json-schema.")
            }

            let nearCoordinate: Coordinate?
            if let near {
                guard let parsed = Coordinate(string: near) else {
                    throw CLIError.user("Near coordinate must be in 'lat,lon' format with valid ranges.")
                }
                nearCoordinate = parsed
            } else {
                nearCoordinate = nil
            }

            let response = try await runner.execute(
                query: query,
                near: nearCoordinate,
                radiusMeters: radius,
                limit: limit
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
            StderrOutput().writeLine("Unexpected search command failure: \(error.localizedDescription)")
            throw ExitCode(rawValue: 2)
        }
    }
}
