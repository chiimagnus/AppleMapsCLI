import Foundation

enum MapsURLBuilderError: Error, Sendable, Equatable {
    case invalidInput(String)
}

enum MapsURLBuilder {
    static func search(query: String) throws -> URL {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw MapsURLBuilderError.invalidInput("Search query cannot be empty.")
        }
        return try buildURL(queryItems: [URLQueryItem(name: "q", value: trimmed)])
    }

    static func location(coordinate: Coordinate, zoom: Int?) throws -> URL {
        if let zoom, !(2...21).contains(zoom) {
            throw MapsURLBuilderError.invalidInput("Zoom must be between 2 and 21.")
        }

        var items = [URLQueryItem(
            name: "ll",
            value: "\(coordinate.lat),\(coordinate.lon)"
        )]
        if let zoom {
            items.append(URLQueryItem(name: "z", value: String(zoom)))
        }
        return try buildURL(queryItems: items)
    }

    static func directions(from: String, to: String, mode: TransportMode) throws -> URL {
        let trimmedFrom = from.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFrom.isEmpty else {
            throw MapsURLBuilderError.invalidInput("Origin (--from) cannot be empty.")
        }

        let trimmedTo = to.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTo.isEmpty else {
            throw MapsURLBuilderError.invalidInput("Destination (--to) cannot be empty.")
        }

        let flag: String
        switch mode {
        case .driving:
            flag = "d"
        case .walking:
            flag = "w"
        case .transit:
            flag = "r"
        case .cycling:
            throw MapsURLBuilderError.invalidInput(
                "Cycling mode is not supported for maps URL directions."
            )
        }

        return try buildURL(queryItems: [
            URLQueryItem(name: "saddr", value: trimmedFrom),
            URLQueryItem(name: "daddr", value: trimmedTo),
            URLQueryItem(name: "dirflg", value: flag)
        ])
    }

    private static func buildURL(queryItems: [URLQueryItem]) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "maps.apple.com"
        components.queryItems = queryItems

        guard let url = components.url else {
            throw MapsURLBuilderError.invalidInput("Failed to build maps URL.")
        }

        return url
    }
}
