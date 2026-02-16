import ArgumentParser
import Foundation

struct CategoriesCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "categories",
        abstract: "List supported MapKit point-of-interest categories."
    )

    @Option(name: .long, help: "Output format: json, text, table")
    var format: String = OutputFormat.json.rawValue

    @Option(name: .long, help: "Comma-separated JSON fields to include in output")
    var fields: String?

    @Flag(name: .long, help: "Force pretty-printed JSON output")
    var pretty: Bool = false

    @Flag(name: .long, help: "Print command input/output JSON schema and exit")
    var jsonSchema: Bool = false

    mutating func run() throws {
        let runner = CategoriesRunner(categoriesService: MapKitCategoriesService())

        do {
            let parsedFormat = try Self.parseFormat(rawValue: format)

            if parsedFormat != .json, fields != nil {
                throw CLIError.user("--fields is only supported with --format json.")
            }

            if jsonSchema {
                let output = try CommandSchemaOutput.render(
                    command: "categories",
                    pretty: pretty,
                    fields: parsedFormat == .json ? fields : nil
                )
                print(output)
                return
            }

            let response = try runner.execute()
            let output: String

            switch parsedFormat {
            case .json:
                output = try JSONOutputFormatter.format(
                    response,
                    forcePretty: pretty,
                    fields: fields
                )
            case .text:
                output = CategoriesOutputFormatter.text(response.results)
            case .table:
                output = CategoriesOutputFormatter.table(response.results)
            }

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
            StderrOutput().writeLine("Unexpected categories command failure: \(error.localizedDescription)")
            throw ExitCode(rawValue: 2)
        }
    }

    static func parseFormat(rawValue: String) throws -> OutputFormat {
        let normalized = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard let format = OutputFormat(rawValue: normalized) else {
            throw CLIError.user("Format must be one of: json, text, table.")
        }

        return format
    }
}

extension CategoriesCommand {
    enum OutputFormat: String, CaseIterable, Sendable {
        case json
        case text
        case table
    }
}
