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
}
