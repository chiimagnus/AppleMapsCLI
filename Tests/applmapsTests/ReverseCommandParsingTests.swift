import Testing
@testable import applmaps

@Suite("Reverse Command Parsing Tests")
struct ReverseCommandParsingTests {
    @Test("Parses negative longitude as positional argument")
    func negativeLongitudePositional() throws {
        let parsed = try ReverseCommand.parse([
            "37.3349",
            "-122.0090"
        ])

        #expect(parsed.coordinates == ["37.3349", "-122.0090"])
    }

    @Test("Parses negative latitude and longitude as positional arguments")
    func negativeLatitudeAndLongitudePositional() throws {
        let parsed = try ReverseCommand.parse([
            "-37.3349",
            "-122.0090"
        ])

        #expect(parsed.coordinates == ["-37.3349", "-122.0090"])
    }

    @Test("Parses pretty flag before coordinates")
    func prettyFlagBeforeCoordinates() throws {
        let parsed = try ReverseCommand.parse([
            "--pretty",
            "37.3349",
            "-122.0090"
        ])

        #expect(parsed.pretty)
        #expect(parsed.coordinates == ["37.3349", "-122.0090"])
    }
}
