import Testing
@testable import applmaps

@Suite("Pin Command Parsing Tests")
struct PinCommandParsingTests {
    @Test("Passthrough captures trailing options")
    func parseCaptureBehavior() throws {
        let parsed = try PinCommand.parse([
            "37.78",
            "-122.41",
            "--label", "Office",
            "--pretty"
        ])

        #expect(parsed.coordinates == ["37.78", "-122.41", "--label", "Office", "--pretty"])
        #expect(parsed.label == nil)
        #expect(!parsed.pretty)
    }

    @Test("Parses fields option before coordinates")
    func fieldsBeforeCoordinates() throws {
        let parsed = try PinCommand.parse([
            "--fields",
            "url",
            "37.78",
            "-122.41"
        ])

        #expect(parsed.fields == "url")
        #expect(parsed.coordinates == ["37.78", "-122.41"])
    }

    @Test("Resolves trailing label and pretty from passthrough tokens")
    func resolveTrailingOptions() throws {
        let resolved = try PinCommand.parseInputs(
            tokens: ["37.78", "-122.41", "--label", "Office", "--pretty"],
            defaultLabel: nil,
            defaultPretty: false,
            defaultFields: nil
        )

        #expect(resolved.coordinate == Coordinate(lat: 37.78, lon: -122.41))
        #expect(resolved.label == "Office")
        #expect(resolved.pretty)
    }

    @Test("Supports negative coordinates")
    func negativeCoordinates() throws {
        let resolved = try PinCommand.parseInputs(
            tokens: ["-37.78", "-122.41"],
            defaultLabel: nil,
            defaultPretty: false,
            defaultFields: nil
        )

        #expect(resolved.coordinate == Coordinate(lat: -37.78, lon: -122.41))
    }

    @Test("Resolves trailing fields option from passthrough tokens")
    func resolveTrailingFields() throws {
        let resolved = try PinCommand.parseInputs(
            tokens: ["37.78", "-122.41", "--fields", "url,opened"],
            defaultLabel: nil,
            defaultPretty: false,
            defaultFields: nil
        )

        #expect(resolved.fields == "url,opened")
    }
}
