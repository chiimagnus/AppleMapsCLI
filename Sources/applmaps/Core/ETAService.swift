import CoreLocation
import Foundation
import MapKit

protocol ETAService: Sendable {
    func eta(
        from: String,
        to destinations: [String],
        mode: TransportMode
    ) async throws -> [ETAResult]
}

enum ETAServiceError: Error, Sendable, Equatable {
    case invalidInput(String)
    case network(String)
    case noResults(String)
}

actor MapKitETAService: ETAService {
    func eta(
        from: String,
        to destinations: [String],
        mode: TransportMode
    ) async throws -> [ETAResult] {
        let trimmedFrom = from.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFrom.isEmpty else {
            throw ETAServiceError.invalidInput("Origin (--from) cannot be empty.")
        }

        guard !destinations.isEmpty else {
            throw ETAServiceError.invalidInput("Provide at least one destination with --to.")
        }

        let transportType = try Self.transportType(for: mode)
        let sourceMapItem = try await resolveMapItem(for: trimmedFrom)
        var results: [ETAResult] = []

        for destination in destinations {
            let trimmedDestination = destination.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedDestination.isEmpty else {
                throw ETAServiceError.invalidInput("Destination values in --to cannot be empty.")
            }

            let destinationMapItem = try await resolveMapItem(for: trimmedDestination)
            let request = MKDirections.Request()
            request.source = sourceMapItem
            request.destination = destinationMapItem
            request.transportType = transportType

            do {
                let etaResponse = try await MKDirections(request: request).calculateETA()
                let result = try Self.makeResult(
                    response: etaResponse,
                    requestedDestination: trimmedDestination,
                    fallbackMode: mode
                )
                results.append(result)
            } catch let error as ETAServiceError {
                throw error
            } catch let error as MKError {
                throw Self.mapMKError(error)
            } catch {
                throw ETAServiceError.network("ETA request failed: \(error.localizedDescription)")
            }
        }

        guard !results.isEmpty else {
            throw ETAServiceError.noResults("No ETA results found.")
        }

        return results
    }

    private func resolveMapItem(for query: String) async throws -> MKMapItem {
        if let coordinate = Coordinate(string: query) {
            let placemark = MKPlacemark(
                coordinate: CLLocationCoordinate2D(latitude: coordinate.lat, longitude: coordinate.lon)
            )
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = query
            return mapItem
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        do {
            let response = try await MKLocalSearch(request: request).start()
            guard let mapItem = response.mapItems.first else {
                throw ETAServiceError.noResults("No location results found.")
            }
            return mapItem
        } catch let error as ETAServiceError {
            throw error
        } catch let error as MKError {
            throw Self.mapMKError(error)
        } catch {
            throw ETAServiceError.network("Location search failed: \(error.localizedDescription)")
        }
    }

    private static func makeResult(
        response: MKDirections.ETAResponse,
        requestedDestination: String,
        fallbackMode: TransportMode
    ) throws -> ETAResult {
        guard let location = response.destination.placemark.location else {
            throw ETAServiceError.noResults("No ETA results found.")
        }

        let destination: String
        if let name = response.destination.name?.trimmingCharacters(in: .whitespacesAndNewlines),
           !name.isEmpty {
            destination = name
        } else {
            destination = requestedDestination
        }

        return ETAResult(
            destination: destination,
            coordinate: Coordinate(
                lat: location.coordinate.latitude,
                lon: location.coordinate.longitude
            ),
            transportType: transportLabel(for: response.transportType, fallback: fallbackMode),
            distanceM: response.distance,
            distanceText: distanceText(meters: response.distance),
            travelTimeS: response.expectedTravelTime,
            travelTimeText: travelTimeText(seconds: response.expectedTravelTime),
            expectedArrival: iso8601(date: response.expectedArrivalDate)
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
                throw ETAServiceError.network("Cycling mode requires macOS 14 or later.")
            }
            return .cycling
        }
    }

    private static func mapMKError(_ error: MKError) -> ETAServiceError {
        switch error.code {
        case .placemarkNotFound, .directionsNotFound:
            return ETAServiceError.noResults("No ETA results found.")
        case .loadingThrottled:
            return ETAServiceError.network("ETA request was throttled. Please retry shortly.")
        default:
            return ETAServiceError.network("Map request failed: \(error.localizedDescription)")
        }
    }

    private static func distanceText(meters: Double) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .medium
        formatter.unitOptions = .naturalScale
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter.string(from: Measurement(value: meters, unit: UnitLength.meters))
    }

    private static func travelTimeText(seconds: TimeInterval) -> String {
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

    private static func iso8601(date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
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
