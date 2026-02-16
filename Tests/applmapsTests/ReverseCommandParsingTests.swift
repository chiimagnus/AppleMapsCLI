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

    @Test("Parses fields flag before coordinates")
    func fieldsFlagBeforeCoordinates() throws {
        let parsed = try ReverseCommand.parse([
            "--fields",
            "coordinate",
            "37.3349",
            "-122.0090"
        ])

        #expect(parsed.fields == "coordinate")
        #expect(parsed.coordinates == ["37.3349", "-122.0090"])
    }

    @Test("Resolves trailing fields from passthrough coordinates")
    func resolveTrailingFieldsFromPassthrough() throws {
        let parsed = try ReverseCommand.parse([
            "37.3349",
            "-122.0090",
            "--fields",
            "coordinate"
        ])

        let resolved = try ReverseCommand.parseInputs(
            tokens: parsed.coordinates,
            defaultPretty: parsed.pretty,
            defaultFields: parsed.fields,
            defaultJSONSchema: parsed.jsonSchema
        )

        #expect(resolved.coordinate == Coordinate(lat: 37.3349, lon: -122.0090))
        #expect(resolved.fields == "coordinate")
        #expect(!resolved.jsonSchema)
    }

    @Test("Parses schema flag with no coordinates")
    func parseSchemaFlag() throws {
        let parsed = try ReverseCommand.parse(["--json-schema"])
        let resolved = try ReverseCommand.parseInputs(
            tokens: parsed.coordinates,
            defaultPretty: parsed.pretty,
            defaultFields: parsed.fields,
            defaultJSONSchema: parsed.jsonSchema
        )

        #expect(resolved.coordinate == nil)
        #expect(resolved.jsonSchema)
    }
}
