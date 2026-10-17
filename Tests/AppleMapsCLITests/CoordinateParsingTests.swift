import Testing
@testable import AppleMapsCLI

@Suite("Coordinate Parsing Tests")
struct CoordinateParsingTests {
    @Test("Parses valid lat lon format")
    func validCoordinate() {
        let coordinate = Coordinate(string: "40.71,-74.00")

        #expect(coordinate == Coordinate(lat: 40.71, lon: -74.00))
    }

    @Test("Rejects invalid formats", arguments: [
        "",
        "40.71",
        "40.71,-74.00,10",
        "lat,lon",
        "91,0",
        "0,181"
    ])
    func invalidCoordinate(input: String) {
        #expect(Coordinate(string: input) == nil)
    }
}
