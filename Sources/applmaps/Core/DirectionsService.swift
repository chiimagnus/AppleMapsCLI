import CoreLocation
import Foundation
import MapKit

protocol DirectionsService: Sendable {
    func directions(
        from: String,
        to: String,
        mode: TransportMode,
        alternatives: Bool
    ) async throws -> DirectionsResponse
}

enum DirectionsServiceError: Error, Sendable, Equatable {
    case invalidInput(String)
    case network(String)
    case noResults(String)
}

actor MapKitDirectionsService: DirectionsService {
    func directions(
        from: String,
        to: String,
        mode: TransportMode,
        alternatives: Bool
    ) async throws -> DirectionsResponse {
        let trimmedFrom = from.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFrom.isEmpty else {
            throw DirectionsServiceError.invalidInput("Origin (--from) cannot be empty.")
        }

        let trimmedTo = to.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTo.isEmpty else {
            throw DirectionsServiceError.invalidInput("Destination (--to) cannot be empty.")
        }

        let sourceMapItem = try await resolveMapItem(for: trimmedFrom)
        let destinationMapItem = try await resolveMapItem(for: trimmedTo)

        let request = MKDirections.Request()
        request.source = sourceMapItem
        request.destination = destinationMapItem
        request.transportType = try Self.transportType(for: mode)
        request.requestsAlternateRoutes = alternatives

        do {
            let response = try await MKDirections(request: request).calculate()
            let routes = response.routes.map(Self.makeRoute(from:))
            guard !routes.isEmpty else {
                throw DirectionsServiceError.noResults("No directions found.")
            }
            let resolvedTransportType = response.routes.first.map(\.transportType)
                ?? request.transportType

            return DirectionsResponse(
                origin: try Self.endpoint(
                    from: response.source,
                    fallbackName: trimmedFrom
                ),
                destination: try Self.endpoint(
                    from: response.destination,
                    fallbackName: trimmedTo
                ),
                transportType: Self.transportLabel(
                    for: resolvedTransportType,
                    fallback: mode
                ),
                routes: routes
            )
        } catch let error as DirectionsServiceError {
            throw error
        } catch let error as MKError {
            throw Self.mapMKError(error)
        } catch {
            throw DirectionsServiceError.network("Directions request failed: \(error.localizedDescription)")
        }
    }

    private func resolveMapItem(for query: String) async throws -> MKMapItem {
        if let coordinate = Coordinate(string: query) {
            let placemark = MKPlacemark(
                coordinate: CLLocationCoordinate2D(latitude: coordinate.lat, longitude: coordinate.lon)
            )
            let item = MKMapItem(placemark: placemark)
            item.name = query
            return item
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        do {
            let response = try await MKLocalSearch(request: request).start()
            guard let item = response.mapItems.first else {
                throw DirectionsServiceError.noResults("No location results found.")
            }
            return item
        } catch let error as DirectionsServiceError {
            throw error
        } catch let error as MKError {
            throw Self.mapMKError(error)
        } catch {
            throw DirectionsServiceError.network("Location search failed: \(error.localizedDescription)")
        }
    }

    private static func endpoint(from mapItem: MKMapItem, fallbackName: String) throws -> RouteEndpoint {
        guard let location = mapItem.placemark.location else {
            throw DirectionsServiceError.noResults("No directions found.")
        }

        let resolvedName: String
        if let name = mapItem.name?.trimmingCharacters(in: .whitespacesAndNewlines),
           !name.isEmpty {
            resolvedName = name
        } else {
            resolvedName = fallbackName
        }

        return RouteEndpoint(
            name: resolvedName,
            coordinate: Coordinate(
                lat: location.coordinate.latitude,
                lon: location.coordinate.longitude
            )
        )
    }

    private static func makeRoute(from route: MKRoute) -> Route {
        let routeName = route.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return Route(
            name: routeName.isEmpty ? "Route" : routeName,
            distanceM: route.distance,
            distanceText: distanceText(meters: route.distance),
            durationS: route.expectedTravelTime,
            durationText: durationText(seconds: route.expectedTravelTime),
            advisoryNotices: route.advisoryNotices,
            steps: route.steps.compactMap { step in
                makeStep(from: step)
            }
        )
    }

    private static func makeStep(from step: MKRoute.Step) -> RouteStep? {
        let instruction = step.instructions.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedInstruction = instruction.isEmpty ? "Continue" : instruction

        if step.distance <= 0, instruction.isEmpty {
            return nil
        }

        return RouteStep(
            instruction: normalizedInstruction,
            distanceM: step.distance,
            distanceText: distanceText(meters: step.distance)
        )
    }

    private static func transportType(for mode: TransportMode) throws -> MKDirectionsTransportType {
        switch mode {
        case .driving:
            return .automobile
        case .walking:
            return .walking
        case .transit:
            return .transit
        case .cycling:
            guard ProcessInfo.processInfo.isOperatingSystemAtLeast(
                OperatingSystemVersion(majorVersion: 14, minorVersion: 0, patchVersion: 0)
            ) else {
                throw DirectionsServiceError.network("Cycling mode requires macOS 14 or later.")
            }
            return .cycling
        }
    }

    private static func mapMKError(_ error: MKError) -> DirectionsServiceError {
        switch error.code {
        case .placemarkNotFound, .directionsNotFound:
            return DirectionsServiceError.noResults("No directions found.")
        case .loadingThrottled:
            return DirectionsServiceError.network("Directions request was throttled. Please retry shortly.")
        default:
            return DirectionsServiceError.network("Directions failed: \(error.localizedDescription)")
        }
    }

    private static func distanceText(meters: Double) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .medium
        formatter.unitOptions = .naturalScale
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter.string(from: Measurement(value: meters, unit: UnitLength.meters))
    }

    private static func durationText(seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        formatter.zeroFormattingBehavior = [.dropLeading]

        if let text = formatter.string(from: max(0, seconds)), !text.isEmpty {
            return text
        }

        return "\(Int(max(0, seconds).rounded())) sec"
    }

    private static func transportLabel(
        for transportType: MKDirectionsTransportType,
        fallback: TransportMode
    ) -> String {
        if transportType.contains(.automobile) {
            return TransportMode.driving.rawValue
        }
        if transportType.contains(.walking) {
            return TransportMode.walking.rawValue
        }
        if transportType.contains(.transit) {
            return TransportMode.transit.rawValue
        }
        if transportType.contains(.cycling) {
            return TransportMode.cycling.rawValue
        }
        return fallback.rawValue
    }
}
