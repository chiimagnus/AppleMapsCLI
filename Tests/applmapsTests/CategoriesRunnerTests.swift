import Testing
@testable import applmaps

@Suite("Categories Runner Tests")
struct CategoriesRunnerTests {
    @Test("Returns sorted unique categories")
    func success() throws {
        let runner = CategoriesRunner(
            categoriesService: MockCategoriesService(items: [
                POICategory(id: "zoo", mapkitValue: "MKPOICategoryZoo"),
                POICategory(id: "airport", mapkitValue: "MKPOICategoryAirport"),
                POICategory(id: "zoo", mapkitValue: "MKPOICategoryZoo")
            ])
        )

        let response = try runner.execute()

        #expect(response.count == 2)
        #expect(response.results.map(\.id) == ["airport", "zoo"])
    }

    @Test("Empty categories map to semantic no-results error")
    func emptyCategories() {
        let runner = CategoriesRunner(
            categoriesService: MockCategoriesService(items: [])
        )

        #expect(throws: CLIError.noResults("No categories are available.")) {
            try runner.execute()
        }
    }
}

private struct MockCategoriesService: CategoriesService {
    let items: [POICategory]

    func categories() -> [POICategory] {
        items
    }
}
