import Testing
@testable import applmaps

@Suite("Search Command Parsing Tests")
struct SearchCommandParsingTests {
    @Test("Parses query and optional flags")
    func parseAllFlags() throws {
        let parsed = try SearchCommand.parse([
            "restaurants",
            "--near", "40.71,-74.00",
            "--radius", "500",
            "--limit", "5",
            "--pretty"
        ])

        #expect(parsed.query == "restaurants")
        #expect(parsed.near == "40.71,-74.00")
        #expect(parsed.radius == 500)
        #expect(parsed.limit == 5)
        #expect(parsed.pretty)
    }

    @Test("Uses default limit when not provided")
    func defaultLimit() throws {
        let parsed = try SearchCommand.parse(["coffee"])

        #expect(parsed.query == "coffee")
        #expect(parsed.limit == 10)
    }
}
