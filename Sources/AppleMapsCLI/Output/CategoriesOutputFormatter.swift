import Foundation

enum CategoriesOutputFormatter {
    static func text(_ categories: [POICategory]) -> String {
        categories.map(\.id).joined(separator: "\n")
    }

    static func table(_ categories: [POICategory]) -> String {
        let idHeader = "id"
        let mapkitHeader = "mapkit_value"

        let idWidth = max(idHeader.count, categories.map { $0.id.count }.max() ?? 0)
        let mapkitWidth = max(mapkitHeader.count, categories.map { $0.mapkitValue.count }.max() ?? 0)

        var lines: [String] = []
        lines.append("\(idHeader.padded(to: idWidth)) | \(mapkitHeader.padded(to: mapkitWidth))")
        lines.append("\(String(repeating: "-", count: idWidth)) | \(String(repeating: "-", count: mapkitWidth))")

        for category in categories {
            lines.append("\(category.id.padded(to: idWidth)) | \(category.mapkitValue.padded(to: mapkitWidth))")
        }

        return lines.joined(separator: "\n")
    }
}

private extension String {
    func padded(to width: Int) -> String {
        guard count < width else {
            return self
        }

        return self + String(repeating: " ", count: width - count)
    }
}
