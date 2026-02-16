import Testing
@testable import applmaps

@Suite("Directions Command Parsing Tests")
struct DirectionsCommandParsingTests {
    @Test("Parses required options and optional flags")
    func parseAllFlags() throws {
        let parsed = try DirectionsCommand.parse([
            "--from", "Cupertino",
            "--to", "San Francisco",
            "--mode", "walking",
            "--alternatives",
            "--fields", "routes",
            "--pretty"
        ])

        #expect(parsed.from == "Cupertino")
        #expect(parsed.to == "San Francisco")
        #expect(parsed.mode == "walking")
        #expect(parsed.alternatives)
        #expect(parsed.fields == "routes")
        #expect(parsed.pretty)
    }

    @Test("Uses default mode and alternatives")
    func defaults() throws {
        let parsed = try DirectionsCommand.parse([
            "--from", "Cupertino",
            "--to", "San Francisco"
        ])

        #expect(parsed.mode == "driving")
        #expect(!parsed.alternatives)
    }

    @Test("Allows schema flag without required endpoints")
    func schemaWithoutEndpoints() throws {
        let parsed = try DirectionsCommand.parse(["--json-schema"])

        #expect(parsed.from == nil)
        #expect(parsed.to == nil)
        #expect(parsed.jsonSchema)
    }
}
