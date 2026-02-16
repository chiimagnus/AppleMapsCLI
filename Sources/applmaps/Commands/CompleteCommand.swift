import ArgumentParser
import Foundation

struct CompleteCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "complete",
        abstract: "Return autocomplete suggestions for a partial search query."
    )

    @Argument(help: "Partial query to autocomplete")
    var query: String?

    @Option(name: .long, help: "Maximum number of suggestions to return")
    var limit: Int = 10

    @Option(name: .long, help: "Comma-separated JSON fields to include in output")
    var fields: String?

    @Flag(name: .long, help: "Force pretty-printed JSON output")
    var pretty: Bool = false

    @Flag(name: .long, help: "Print command input/output JSON schema and exit")
    var jsonSchema: Bool = false

    mutating func run() async throws {
        let runner = SearchCompletionRunner(searchCompletionService: MapKitSearchCompletionService())

        do {
            if jsonSchema {
                let output = try CommandSchemaOutput.render(
                    command: "complete",
                    pretty: pretty,
                    fields: fields
                )
                print(output)
                return
            }

            guard let query else {
                throw CLIError.user("Provide a query argument or use --json-schema.")
            }

            let response = try await runner.execute(query: query, limit: limit)
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
            StderrOutput().writeLine("Unexpected complete command failure: \(error.localizedDescription)")
            throw ExitCode(rawValue: 2)
        }
    }
}
