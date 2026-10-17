import Testing
@testable import applmaps

@Suite("Open Command Parsing Tests")
struct OpenCommandParsingTests {
    @Test("Parses location mode with zoom")
    func parseLocation() throws {
        let parsed = try OpenCommand.parse([
            "--location", "37.78,-122.41",
            "--zoom", "14",
            "--fields", "url",
            "--pretty"
        ])

        #expect(parsed.location == "37.78,-122.41")
        #expect(parsed.zoom == 14)
        #expect(parsed.fields == "url")
        #expect(parsed.pretty)
    }

    @Test("Parses search mode")
    func parseSearch() throws {
        let parsed = try OpenCommand.parse([
            "--search", "coffee"
        ])

        #expect(parsed.search == "coffee")
        #expect(parsed.mode == "driving")
    }

    @Test("Parses directions mode")
    func parseDirections() throws {
        let parsed = try OpenCommand.parse([
            "--from", "Cupertino",
            "--to", "San Francisco",
            "--mode", "walking"
        ])

        #expect(parsed.from == "Cupertino")
        #expect(parsed.to == "San Francisco")
        #expect(parsed.mode == "walking")
    }

    @Test("Parses repeated ordered waypoints")
    func parseWaypoints() throws {
        let parsed = try OpenCommand.parse([
            "--from", "北京", "--via", "洛阳", "--via", "芜湖",
            "--via", "杭州", "--to", "上海"
        ])
        #expect(parsed.via == ["洛阳", "芜湖", "杭州"])
        #expect(parsed.mode == "driving")
    }

    @Test("Parses schema flag")
    func parseSchemaFlag() throws {
        let parsed = try OpenCommand.parse(["--json-schema"])
        #expect(parsed.jsonSchema)
    }
}
