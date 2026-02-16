import Foundation
import Testing
@testable import applmaps

@Suite("JSON Output Formatter Tests")
struct JSONOutputFormatterTests {
    @Test("Encodes keys in snake_case")
    func snakeCaseEncoding() throws {
        let output = try JSONOutputFormatter.format(
            Fixtures.response,
            forcePretty: false,
            stdoutIsTTY: false
        )

        #expect(output.contains("\"iso_country\""))
        #expect(output.contains("\"areas_of_interest\""))
    }

    @Test("Uses compact JSON when not pretty and not tty")
    func compactOutput() throws {
        let output = try JSONOutputFormatter.format(
            Fixtures.response,
            forcePretty: false,
            stdoutIsTTY: false
        )

        #expect(!output.contains("\n"))
    }

    @Test("Uses pretty JSON when forced")
    func prettyOutput() throws {
        let output = try JSONOutputFormatter.format(
            Fixtures.response,
            forcePretty: true,
            stdoutIsTTY: false
        )

        #expect(output.contains("\n"))
        #expect(output.contains("  \"results\""))
    }

    @Test("Produces valid JSON payload")
    func validJSON() throws {
        let output = try JSONOutputFormatter.format(
            Fixtures.response,
            forcePretty: false,
            stdoutIsTTY: false
        )

        let data = Data(output.utf8)
        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let query = decoded?["query"] as? String

        #expect(query == "Apple Park")
    }

    @Test("Projects top-level fields")
    func projectsTopLevelFields() throws {
        let output = try JSONOutputFormatter.format(
            Fixtures.openResponse,
            forcePretty: false,
            fields: "url,opened",
            stdoutIsTTY: false
        )

        let data = Data(output.utf8)
        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(decoded?["url"] as? String == "https://maps.apple.com/?q=Coffee")
        #expect(decoded?["opened"] as? Bool == false)
        #expect(decoded?["action"] == nil)
    }

    @Test("Projects nested result object fields")
    func projectsNestedResultFields() throws {
        let output = try JSONOutputFormatter.format(
            Fixtures.searchResponse,
            forcePretty: false,
            fields: "name,coordinate",
            stdoutIsTTY: false
        )

        let data = Data(output.utf8)
        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let results = decoded?["results"] as? [[String: Any]]

        #expect(decoded?["query"] == nil)
        #expect(decoded?["count"] == nil)
        #expect(results?.count == 1)
        #expect(results?.first?["name"] as? String == "Coffee Shop")
        #expect(results?.first?["coordinate"] as? [String: Any] != nil)
        #expect(results?.first?["address"] == nil)
    }

    @Test("Rejects empty field names")
    func rejectsEmptyFieldNames() {
        #expect(throws: JSONOutputFormatterError.invalidFields(
            "Fields must be a comma-separated list of non-empty names."
        )) {
            _ = try JSONOutputFormatter.format(
                Fixtures.response,
                forcePretty: false,
                fields: "name,,coordinate",
                stdoutIsTTY: false
            )
        }
    }
}

private enum Fixtures {
    static let response = GeocodeResponse(
        query: "Apple Park",
        results: [
            GeocodeResult(
                coordinate: Coordinate(lat: 37.3349, lon: -122.0090),
                address: Address(
                    street: "1 Apple Park Way",
                    city: "Cupertino",
                    state: "CA",
                    zip: "95014",
                    country: "United States",
                    isoCountry: "US",
                    formatted: "1 Apple Park Way, Cupertino, CA, 95014, United States"
                ),
                timezone: "America/Los_Angeles",
                areasOfInterest: ["Apple Park"]
            )
        ]
    )

    static let openResponse = OpenResponse(
        action: "search",
        url: "https://maps.apple.com/?q=Coffee",
        opened: false
    )

    static let searchResponse = SearchResponse(
        query: "coffee",
        count: 1,
        results: [
            Place(
                name: "Coffee Shop",
                coordinate: Coordinate(lat: 37.33, lon: -122.03),
                address: Address(
                    street: "1 Main St",
                    city: "Cupertino",
                    state: "CA",
                    zip: "95014",
                    country: "United States",
                    isoCountry: "US",
                    formatted: "1 Main St, Cupertino, CA 95014, United States"
                ),
                phone: "555-0100",
                url: "https://example.com",
                category: "MKPOICategoryCafe",
                timezone: "America/Los_Angeles",
                mapsUrl: "https://maps.apple.com/?q=Coffee+Shop"
            )
        ]
    )
}
