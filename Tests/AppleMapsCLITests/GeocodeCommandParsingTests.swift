import Testing
@testable import AppleMapsCLI

@Suite("Geocode Command Parsing Tests")
struct GeocodeCommandParsingTests {
    @Test("Parses positional address and pretty flag")
    func parseAddress() throws {
        let parsed = try GeocodeCommand.parse([
            "1 Apple Park Way",
            "--fields", "coordinate",
            "--pretty"
        ])

        #expect(parsed.address == "1 Apple Park Way")
        #expect(parsed.fields == "coordinate")
        #expect(parsed.pretty)
        #expect(!parsed.stdin)
    }

    @Test("Parses stdin mode without positional address")
    func parseStdin() throws {
        let parsed = try GeocodeCommand.parse(["--stdin"])

        #expect(parsed.stdin)
        #expect(parsed.address == nil)
    }

    @Test("Parses stdin mode with positional address for runtime validation")
    func parseStdinWithAddress() throws {
        let parsed = try GeocodeCommand.parse([
            "--stdin",
            "1 Apple Park Way"
        ])

        #expect(parsed.stdin)
        #expect(parsed.address == "1 Apple Park Way")
    }

    @Test("Parses schema flag without address")
    func parseSchemaFlag() throws {
        let parsed = try GeocodeCommand.parse(["--json-schema"])

        #expect(parsed.jsonSchema)
        #expect(parsed.address == nil)
    }
}
