import Testing
@testable import applmaps

@Suite("ETA Command Parsing Tests")
struct ETACommandParsingTests {
    @Test("Parses required options with repeated destinations")
    func parseRequiredAndRepeatedTo() throws {
        let parsed = try ETACommand.parse([
            "--from", "San Francisco",
            "--to", "Oakland",
            "--to", "San Jose",
            "--mode", "walking",
            "--fields", "destination,travel_time_s",
            "--pretty"
        ])

        #expect(parsed.from == "San Francisco")
        #expect(parsed.to == ["Oakland", "San Jose"])
        #expect(parsed.mode == "walking")
        #expect(parsed.fields == "destination,travel_time_s")
        #expect(parsed.pretty)
    }

    @Test("Uses default driving mode")
    func defaultMode() throws {
        let parsed = try ETACommand.parse([
            "--from", "San Francisco",
            "--to", "Oakland"
        ])

        #expect(parsed.mode == "driving")
        #expect(parsed.to == ["Oakland"])
    }
}
