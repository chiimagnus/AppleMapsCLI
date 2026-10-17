import Foundation

struct CategoriesRunner: Sendable {
    let categoriesService: any CategoriesService

    func execute() throws -> CategoriesResponse {
        var seen = Set<String>()
        var unique: [POICategory] = []

        for category in categoriesService.categories() {
            guard seen.insert(category.id).inserted else {
                continue
            }
            unique.append(category)
        }

        let sorted = unique.sorted { lhs, rhs in
            lhs.id < rhs.id
        }

        guard !sorted.isEmpty else {
            throw CLIError.noResults("No categories are available.")
        }

        return CategoriesResponse(count: sorted.count, results: sorted)
    }
}
