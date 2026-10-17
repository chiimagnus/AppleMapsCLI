import Testing
@testable import AppleMapsCLI

@Suite("Categories Command Parsing Tests")
struct CategoriesCommandParsingTests {
    @Test("Parses format, fields, pretty, and schema flags")
    func parseAllFlags() throws {
        let parsed = try CategoriesCommand.parse([
            "--format", "json",
            "--fields", "results.id",
            "--pretty",
            "--json-schema"
        ])

        #expect(parsed.format == "json")
        #expect(parsed.fields == "results.id")
        #expect(parsed.pretty)
        #expect(parsed.jsonSchema)
    }

    @Test("Uses json as default format")
    func defaultFormat() throws {
        let parsed = try CategoriesCommand.parse([])
        #expect(parsed.format == "json")
    }

    @Test("Rejects unsupported output format at runtime validation")
    func invalidFormat() {
        #expect(throws: CLIError.user("Format must be one of: json, text, table.")) {
            _ = try CategoriesCommand.parseFormat(rawValue: "xml")
        }
    }
}
