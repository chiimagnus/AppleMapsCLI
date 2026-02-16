import Foundation

struct CommandSchemaDocument: Sendable, Codable, Equatable {
    let schemaURL: String
    let command: String
    let input: JSONSchemaNode
    let output: JSONSchemaNode

    enum CodingKeys: String, CodingKey {
        case schemaURL = "$schema"
        case command
        case input
        case output
    }
}

final class JSONSchemaNode: Codable, Equatable, @unchecked Sendable {
    let type: String?
    let description: String?
    let properties: [String: JSONSchemaNode]?
    let items: JSONSchemaNode?
    let required: [String]?
    let enumValues: [String]?
    let oneOf: [JSONSchemaNode]?
    let additionalProperties: Bool?

    enum CodingKeys: String, CodingKey {
        case type
        case description
        case properties
        case items
        case required
        case enumValues = "enum"
        case oneOf
        case additionalProperties
    }

    init(
        type: String? = nil,
        description: String? = nil,
        properties: [String: JSONSchemaNode]? = nil,
        items: JSONSchemaNode? = nil,
        required: [String]? = nil,
        enumValues: [String]? = nil,
        oneOf: [JSONSchemaNode]? = nil,
        additionalProperties: Bool? = nil
    ) {
        self.type = type
        self.description = description
        self.properties = properties
        self.items = items
        self.required = required
        self.enumValues = enumValues
        self.oneOf = oneOf
        self.additionalProperties = additionalProperties
    }

    static func == (lhs: JSONSchemaNode, rhs: JSONSchemaNode) -> Bool {
        lhs.type == rhs.type
            && lhs.description == rhs.description
            && lhs.properties == rhs.properties
            && lhs.items == rhs.items
            && lhs.required == rhs.required
            && lhs.enumValues == rhs.enumValues
            && lhs.oneOf == rhs.oneOf
            && lhs.additionalProperties == rhs.additionalProperties
    }
}

extension JSONSchemaNode {
    static func string(description: String? = nil, enumValues: [String]? = nil) -> JSONSchemaNode {
        JSONSchemaNode(type: "string", description: description, enumValues: enumValues)
    }

    static func number(description: String? = nil) -> JSONSchemaNode {
        JSONSchemaNode(type: "number", description: description)
    }

    static func integer(description: String? = nil) -> JSONSchemaNode {
        JSONSchemaNode(type: "integer", description: description)
    }

    static func boolean(description: String? = nil) -> JSONSchemaNode {
        JSONSchemaNode(type: "boolean", description: description)
    }

    static func array(_ item: JSONSchemaNode, description: String? = nil) -> JSONSchemaNode {
        JSONSchemaNode(type: "array", description: description, items: item)
    }

    static func object(
        properties: [String: JSONSchemaNode],
        required: [String] = [],
        description: String? = nil,
        additionalProperties: Bool = false
    ) -> JSONSchemaNode {
        JSONSchemaNode(
            type: "object",
            description: description,
            properties: properties,
            required: required.isEmpty ? nil : required,
            additionalProperties: additionalProperties
        )
    }

    static func oneOf(_ nodes: [JSONSchemaNode], description: String? = nil) -> JSONSchemaNode {
        JSONSchemaNode(description: description, oneOf: nodes)
    }
}

enum CommandSchemaRegistry {
    static func schema(for command: String) -> CommandSchemaDocument? {
        switch command {
        case "geocode":
            return document(command: "geocode", input: geocodeInput, output: geocodeOutput)
        case "reverse":
            return document(command: "reverse", input: reverseInput, output: reverseOutput)
        case "search":
            return document(command: "search", input: searchInput, output: searchOutput)
        case "complete":
            return document(command: "complete", input: completeInput, output: completeOutput)
        case "directions":
            return document(command: "directions", input: directionsInput, output: directionsOutput)
        case "eta":
            return document(command: "eta", input: etaInput, output: etaOutput)
        case "open":
            return document(command: "open", input: openInput, output: openOutput)
        case "pin":
            return document(command: "pin", input: pinInput, output: pinOutput)
        case "completions":
            return document(command: "completions", input: completionsInput, output: completionsOutput)
        default:
            return nil
        }
    }

    private static func document(
        command: String,
        input: JSONSchemaNode,
        output: JSONSchemaNode
    ) -> CommandSchemaDocument {
        CommandSchemaDocument(
            schemaURL: "https://json-schema.org/draft/2020-12/schema",
            command: command,
            input: input,
            output: output
        )
    }

    private static let transportMode = JSONSchemaNode.string(
        description: "Transport mode.",
        enumValues: ["driving", "walking", "transit", "cycling"]
    )

    private static let coordinate = JSONSchemaNode.object(
        properties: [
            "lat": .number(description: "Latitude in decimal degrees."),
            "lon": .number(description: "Longitude in decimal degrees.")
        ],
        required: ["lat", "lon"],
        description: "Latitude/longitude coordinate."
    )

    private static let address = JSONSchemaNode.object(
        properties: [
            "street": .string(),
            "city": .string(),
            "state": .string(),
            "zip": .string(),
            "country": .string(),
            "iso_country": .string(),
            "formatted": .string(description: "Human-readable address.")
        ],
        required: ["formatted"],
        description: "Postal address object."
    )

    private static let geocodeResult = JSONSchemaNode.object(
        properties: [
            "coordinate": coordinate,
            "address": address,
            "timezone": .string(description: "Timezone identifier."),
            "areas_of_interest": .array(.string(), description: "Nearby points of interest.")
        ],
        required: ["coordinate", "address", "areas_of_interest"]
    )

    private static let geocodeSingleOutput = JSONSchemaNode.object(
        properties: [
            "query": .string(),
            "results": .array(geocodeResult)
        ],
        required: ["query", "results"]
    )

    private static let geocodeBatchResult = JSONSchemaNode.object(
        properties: [
            "query": .string(),
            "results": .array(geocodeResult)
        ],
        required: ["query", "results"]
    )

    private static let geocodeBatchOutput = JSONSchemaNode.object(
        properties: [
            "count": .integer(),
            "results": .array(geocodeBatchResult)
        ],
        required: ["count", "results"]
    )

    private static let place = JSONSchemaNode.object(
        properties: [
            "name": .string(),
            "coordinate": coordinate,
            "address": address,
            "phone": .string(),
            "url": .string(),
            "category": .string(),
            "timezone": .string(),
            "maps_url": .string()
        ],
        required: ["name", "coordinate", "address", "maps_url"]
    )

    private static let searchCompletion = JSONSchemaNode.object(
        properties: [
            "title": .string(),
            "subtitle": .string(),
            "display": .string()
        ],
        required: ["title", "subtitle", "display"]
    )

    private static let routeStep = JSONSchemaNode.object(
        properties: [
            "instruction": .string(),
            "distance_m": .number(),
            "distance_text": .string()
        ],
        required: ["instruction", "distance_m", "distance_text"]
    )

    private static let route = JSONSchemaNode.object(
        properties: [
            "name": .string(),
            "distance_m": .number(),
            "distance_text": .string(),
            "duration_s": .number(),
            "duration_text": .string(),
            "advisory_notices": .array(.string()),
            "steps": .array(routeStep)
        ],
        required: [
            "name",
            "distance_m",
            "distance_text",
            "duration_s",
            "duration_text",
            "advisory_notices",
            "steps"
        ]
    )

    private static let routeEndpoint = JSONSchemaNode.object(
        properties: [
            "name": .string(),
            "coordinate": coordinate
        ],
        required: ["name", "coordinate"]
    )

    private static let etaResult = JSONSchemaNode.object(
        properties: [
            "destination": .string(),
            "coordinate": coordinate,
            "transport_type": .string(),
            "distance_m": .number(),
            "distance_text": .string(),
            "travel_time_s": .number(),
            "travel_time_text": .string(),
            "expected_arrival": .string(description: "ISO 8601 arrival timestamp.")
        ],
        required: [
            "destination",
            "coordinate",
            "transport_type",
            "distance_m",
            "distance_text",
            "travel_time_s",
            "travel_time_text"
        ]
    )

    private static let openResponse = JSONSchemaNode.object(
        properties: [
            "action": .string(),
            "url": .string(),
            "opened": .boolean()
        ],
        required: ["action", "url", "opened"]
    )

    private static let geocodeInput = JSONSchemaNode.object(
        properties: [
            "address": .string(description: "Address query to geocode."),
            "stdin": .boolean(description: "Read one address per stdin line."),
            "fields": .string(description: "Comma-separated JSON fields projection."),
            "pretty": .boolean(description: "Pretty-print JSON output."),
            "json_schema": .boolean(description: "Return this command schema instead of executing.")
        ],
        description: "Input options for geocode."
    )

    private static let geocodeOutput = JSONSchemaNode.oneOf(
        [geocodeSingleOutput, geocodeBatchOutput],
        description: "Single geocode output or stdin batch output."
    )

    private static let reverseInput = JSONSchemaNode.object(
        properties: [
            "lat": .number(description: "Latitude in decimal degrees."),
            "lon": .number(description: "Longitude in decimal degrees."),
            "fields": .string(description: "Comma-separated JSON fields projection."),
            "pretty": .boolean(description: "Pretty-print JSON output."),
            "json_schema": .boolean(description: "Return this command schema instead of executing.")
        ],
        required: ["lat", "lon"]
    )

    private static let reverseOutput = JSONSchemaNode.object(
        properties: [
            "coordinate": coordinate,
            "results": .array(geocodeResult)
        ],
        required: ["coordinate", "results"]
    )

    private static let searchInput = JSONSchemaNode.object(
        properties: [
            "query": .string(description: "Natural-language search query."),
            "near": .string(description: "Bias around a coordinate string in 'lat,lon' format."),
            "radius": .number(description: "Search radius in meters."),
            "limit": .integer(description: "Maximum result count."),
            "fields": .string(description: "Comma-separated JSON fields projection."),
            "pretty": .boolean(description: "Pretty-print JSON output."),
            "json_schema": .boolean(description: "Return this command schema instead of executing.")
        ],
        required: ["query"]
    )

    private static let searchOutput = JSONSchemaNode.object(
        properties: [
            "query": .string(),
            "count": .integer(),
            "results": .array(place)
        ],
        required: ["query", "count", "results"]
    )

    private static let completeInput = JSONSchemaNode.object(
        properties: [
            "query": .string(description: "Partial query for autocomplete suggestions."),
            "limit": .integer(description: "Maximum suggestion count."),
            "fields": .string(description: "Comma-separated JSON fields projection."),
            "pretty": .boolean(description: "Pretty-print JSON output."),
            "json_schema": .boolean(description: "Return this command schema instead of executing.")
        ],
        required: ["query"]
    )

    private static let completeOutput = JSONSchemaNode.object(
        properties: [
            "query": .string(),
            "count": .integer(),
            "results": .array(searchCompletion)
        ],
        required: ["query", "count", "results"]
    )

    private static let directionsInput = JSONSchemaNode.object(
        properties: [
            "from": .string(description: "Origin query or coordinate."),
            "to": .string(description: "Destination query or coordinate."),
            "mode": transportMode,
            "alternatives": .boolean(description: "Request alternate routes."),
            "fields": .string(description: "Comma-separated JSON fields projection."),
            "pretty": .boolean(description: "Pretty-print JSON output."),
            "json_schema": .boolean(description: "Return this command schema instead of executing.")
        ],
        required: ["from", "to"]
    )

    private static let directionsOutput = JSONSchemaNode.object(
        properties: [
            "origin": routeEndpoint,
            "destination": routeEndpoint,
            "transport_type": .string(),
            "routes": .array(route)
        ],
        required: ["origin", "destination", "transport_type", "routes"]
    )

    private static let etaInput = JSONSchemaNode.object(
        properties: [
            "from": .string(description: "Origin query or coordinate."),
            "to": .array(.string(), description: "Destination queries; provide one or more."),
            "mode": transportMode,
            "fields": .string(description: "Comma-separated JSON fields projection."),
            "pretty": .boolean(description: "Pretty-print JSON output."),
            "json_schema": .boolean(description: "Return this command schema instead of executing.")
        ],
        required: ["from", "to"]
    )

    private static let etaOutput = JSONSchemaNode.object(
        properties: [
            "from": .string(),
            "count": .integer(),
            "results": .array(etaResult)
        ],
        required: ["from", "count", "results"]
    )

    private static let openInput = JSONSchemaNode.object(
        properties: [
            "search": .string(description: "Search query mode."),
            "location": .string(description: "Coordinate string in 'lat,lon' format."),
            "from": .string(description: "Directions origin query."),
            "to": .string(description: "Directions destination query."),
            "mode": transportMode,
            "zoom": .integer(description: "Zoom level for location mode (2...21)."),
            "fields": .string(description: "Comma-separated JSON fields projection."),
            "pretty": .boolean(description: "Pretty-print JSON output."),
            "json_schema": .boolean(description: "Return this command schema instead of executing.")
        ],
        description: "Exactly one mode should be selected: search, location, or directions."
    )

    private static let openOutput = openResponse

    private static let pinInput = JSONSchemaNode.object(
        properties: [
            "lat": .number(description: "Latitude in decimal degrees."),
            "lon": .number(description: "Longitude in decimal degrees."),
            "label": .string(description: "Optional pin label."),
            "fields": .string(description: "Comma-separated JSON fields projection."),
            "pretty": .boolean(description: "Pretty-print JSON output."),
            "json_schema": .boolean(description: "Return this command schema instead of executing.")
        ],
        required: ["lat", "lon"]
    )

    private static let pinOutput = openResponse

    private static let completionsInput = JSONSchemaNode.object(
        properties: [
            "shell": .string(enumValues: ["zsh", "bash", "fish"]),
            "json_schema": .boolean(description: "Return this command schema instead of executing.")
        ],
        required: ["shell"]
    )

    private static let completionsOutput = JSONSchemaNode.string(
        description: "Shell completion script text."
    )
}
