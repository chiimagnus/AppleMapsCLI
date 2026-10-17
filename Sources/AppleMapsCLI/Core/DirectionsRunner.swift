import Foundation

struct DirectionsRunner: Sendable {
    let directionsService: any DirectionsService

    func executeItinerary(
        from: String,
        via: [String],
        to: String,
        mode: TransportMode,
        alternatives: Bool
    ) async throws -> ItineraryDirectionsResponse {
        let stops = ([from] + via + [to]).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard !stops[0].isEmpty else {
            throw CLIError.user("Origin (--from) cannot be empty.")
        }
        guard !stops[stops.count - 1].isEmpty else {
            throw CLIError.user("Destination (--to) cannot be empty.")
        }
        for (index, stop) in stops.dropFirst().dropLast().enumerated() where stop.isEmpty {
            throw CLIError.user("Waypoint \(index + 1) cannot be empty.")
        }

        var legs: [DirectionsResponse] = []
        var totalDistance = 0.0
        var totalDuration = 0.0
        for index in 0..<(stops.count - 1) {
            do {
                let leg = try await execute(
                    from: stops[index],
                    to: stops[index + 1],
                    mode: mode,
                    alternatives: alternatives
                )
                guard let chosenRoute = leg.routes.first else {
                    throw CLIError.noResults("No directions found.")
                }
                legs.append(leg)
                totalDistance += chosenRoute.distanceM
                totalDuration += chosenRoute.durationS
            } catch let error as CLIError {
                let prefix = "Leg \(index + 1)/\(stops.count - 1): "
                switch error {
                case let .user(message):
                    throw CLIError.user(prefix + message)
                case let .network(message):
                    throw CLIError.network(prefix + message)
                case let .noResults(message):
                    throw CLIError.noResults(prefix + message)
                }
            }
        }

        return ItineraryDirectionsResponse(
            from: stops[0],
            via: Array(stops.dropFirst().dropLast()),
            to: stops[stops.count - 1],
            transportType: mode.rawValue,
            totalDistanceM: totalDistance,
            totalDurationS: totalDuration,
            legs: legs
        )
    }

    func execute(
        from: String,
        to: String,
        mode: TransportMode,
        alternatives: Bool
    ) async throws -> DirectionsResponse {
        let trimmedFrom = from.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFrom.isEmpty else {
            throw CLIError.user("Origin (--from) cannot be empty.")
        }

        let trimmedTo = to.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTo.isEmpty else {
            throw CLIError.user("Destination (--to) cannot be empty.")
        }

        do {
            let response = try await directionsService.directions(
                from: trimmedFrom,
                to: trimmedTo,
                mode: mode,
                alternatives: alternatives
            )

            guard !response.routes.isEmpty else {
                throw CLIError.noResults("No directions found.")
            }

            return response
        } catch let error as DirectionsServiceError {
            switch error {
            case let .invalidInput(message):
                throw CLIError.user(message)
            case let .network(message):
                throw CLIError.network(message)
            case let .noResults(message):
                throw CLIError.noResults(message)
            }
        } catch let error as CLIError {
            throw error
        } catch {
            throw CLIError.network("Unexpected directions error: \(error.localizedDescription)")
        }
    }
}
