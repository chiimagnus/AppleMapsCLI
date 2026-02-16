import Testing
@testable import applmaps

@Suite("Maps URL Builder Tests")
struct MapsURLBuilderTests {
    @Test("Builds search URL")
    func searchURL() throws {
        let url = try MapsURLBuilder.search(query: "coffee near me")
        #expect(url.absoluteString == "https://maps.apple.com?q=coffee%20near%20me")
    }

    @Test("Builds location URL with zoom")
    func locationURL() throws {
        let url = try MapsURLBuilder.location(
            coordinate: Coordinate(lat: 37.78, lon: -122.41),
            zoom: 14
        )
        #expect(url.absoluteString == "https://maps.apple.com?ll=37.78,-122.41&z=14")
    }

    @Test("Builds driving directions URL")
    func drivingDirectionsURL() throws {
        let url = try MapsURLBuilder.directions(
            from: "Cupertino",
            to: "San Francisco",
            mode: .driving
        )
        #expect(url.absoluteString == "https://maps.apple.com?saddr=Cupertino&daddr=San%20Francisco&dirflg=d")
    }

    @Test("Cycling directions are rejected for maps URL")
    func cyclingRejected() throws {
        #expect(throws: MapsURLBuilderError.invalidInput(
            "Cycling mode is not supported for maps URL directions."
        )) {
            try MapsURLBuilder.directions(
                from: "A",
                to: "B",
                mode: .cycling
            )
        }
    }
}
