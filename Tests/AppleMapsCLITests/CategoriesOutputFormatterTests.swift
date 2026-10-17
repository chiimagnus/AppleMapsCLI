import Testing
@testable import AppleMapsCLI

@Suite("Categories Output Formatter Tests")
struct CategoriesOutputFormatterTests {
    @Test("Text format emits one id per line")
    func textOutput() {
        let categories = [
            POICategory(id: "airport", mapkitValue: "MKPOICategoryAirport"),
            POICategory(id: "zoo", mapkitValue: "MKPOICategoryZoo")
        ]

        let output = CategoriesOutputFormatter.text(categories)
        #expect(output == "airport\nzoo")
    }

    @Test("Table format includes header and row values")
    func tableOutput() {
        let categories = [
            POICategory(id: "airport", mapkitValue: "MKPOICategoryAirport"),
            POICategory(id: "zoo", mapkitValue: "MKPOICategoryZoo")
        ]

        let output = CategoriesOutputFormatter.table(categories)
        let lines = output.components(separatedBy: .newlines)

        #expect(lines.count == 4)
        #expect(lines[0].contains("id"))
        #expect(lines[0].contains("mapkit_value"))
        #expect(lines[1].contains("-"))
        #expect(lines[2].contains("airport"))
        #expect(lines[2].contains("MKPOICategoryAirport"))
        #expect(lines[3].contains("zoo"))
        #expect(lines[3].contains("MKPOICategoryZoo"))
    }
}
