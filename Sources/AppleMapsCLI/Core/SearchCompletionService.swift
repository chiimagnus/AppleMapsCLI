import Foundation
import MapKit

protocol SearchCompletionService: Sendable {
    func complete(query: String, limit: Int) async throws -> [SearchCompletion]
}

enum SearchCompletionServiceError: Error, Sendable, Equatable {
    case invalidInput(String)
    case network(String)
    case noResults
}

actor MapKitSearchCompletionService: SearchCompletionService {
    func complete(query: String, limit: Int) async throws -> [SearchCompletion] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            throw SearchCompletionServiceError.invalidInput("Search query cannot be empty.")
        }

        guard limit > 0 else {
            throw SearchCompletionServiceError.invalidInput("Limit must be greater than zero.")
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmedQuery
        request.resultTypes = .pointOfInterest

        do {
            let response = try await MKLocalSearch(request: request).start()
            var seen = Set<String>()
            var suggestions: [SearchCompletion] = []

            for mapItem in response.mapItems {
                guard let completion = Self.makeCompletion(from: mapItem) else {
                    continue
                }

                let key = "\(completion.title.lowercased())|\(completion.subtitle.lowercased())"
                guard seen.insert(key).inserted else {
                    continue
                }

                suggestions.append(completion)
                if suggestions.count == limit {
                    break
                }
            }

            guard !suggestions.isEmpty else {
                throw SearchCompletionServiceError.noResults
            }

            return suggestions
        } catch let error as SearchCompletionServiceError {
            throw error
        } catch let error as MKError {
            switch error.code {
            case .placemarkNotFound:
                throw SearchCompletionServiceError.noResults
            case .loadingThrottled:
                throw SearchCompletionServiceError.network(
                    "Autocomplete request was throttled. Please retry shortly."
                )
            default:
                throw SearchCompletionServiceError.network(
                    "Autocomplete failed: \(error.localizedDescription)"
                )
            }
        } catch {
            throw SearchCompletionServiceError.network(
                "Autocomplete failed: \(error.localizedDescription)"
            )
        }
    }

    private static func makeCompletion(from mapItem: MKMapItem) -> SearchCompletion? {
        guard let title = mapItem.name?.trimmedNonEmpty else {
            return nil
        }

        let subtitle = subtitle(for: mapItem.placemark)
        let display = subtitle.isEmpty ? title : "\(title), \(subtitle)"

        return SearchCompletion(
            title: title,
            subtitle: subtitle,
            display: display
        )
    }

    private static func subtitle(for placemark: MKPlacemark) -> String {
        let locality = placemark.locality?.trimmedNonEmpty
        let region = placemark.administrativeArea?.trimmedNonEmpty
        let country = placemark.country?.trimmedNonEmpty

        let components = [locality, region, country].compactMap { $0 }
        if !components.isEmpty {
            return components.joined(separator: ", ")
        }

        return placemark.title?.trimmedNonEmpty ?? ""
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
