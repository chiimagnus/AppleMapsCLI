import Testing
@testable import AppleMapsCLI

@Suite("Complete Command Parsing Tests")
struct CompleteCommandParsingTests {
    @Test("Parses query and optional flags")
    func parseAllFlags() throws {
        let parsed = try CompleteCommand.parse([
            "star",
            "--limit", "5",
            "--fields", "results.title,results.subtitle",
            "--json-schema",
            "--pretty"
        ])

        #expect(parsed.query == "star")
        #expect(parsed.limit == 5)
        #expect(parsed.fields == "results.title,results.subtitle")
        #expect(parsed.jsonSchema)
        #expect(parsed.pretty)
    }

    @Test("Uses default limit when not provided")
    func defaultLimit() throws {
        let parsed = try CompleteCommand.parse(["coffee"])

        #expect(parsed.query == "coffee")
        #expect(parsed.limit == 10)
    }

    @Test("Allows schema flag without positional query")
    func schemaWithoutQuery() throws {
        let parsed = try CompleteCommand.parse(["--json-schema"])

        #expect(parsed.query == nil)
        #expect(parsed.jsonSchema)
    }
}
