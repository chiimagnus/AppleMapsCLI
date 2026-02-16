# `applmaps`: an agent-first Apple Maps CLI tool

**`applmaps` is a native Swift command-line tool that gives AI agents and developers programmatic access to Apple Maps — search, directions, geocoding, and map control — without ever opening Xcode or touching a GUI.** It wraps MapKit's non-UI APIs (MKLocalSearch, MKDirections, CLGeocoder) alongside the `maps://` URL scheme to provide both structured data retrieval and visual map control from the terminal. Designed for the agent-first workflow described in Peter Steinberger's "Shipping at Inference Speed" philosophy, every command outputs machine-readable JSON by default, uses semantic exit codes, and avoids interactive prompts — making it instantly consumable by LLM coding agents, shell scripts, and MCP tool servers alike.

This document specifies the full architecture, API surface, data models, and implementation roadmap for `applmaps`.

---

## Project context and design philosophy

Peter Steinberger's "Shipping at Inference Speed" describes a 2025 development workflow where AI coding agents handle the bulk of code generation, testing, and iteration. Developers operate at a higher level of abstraction — directing agents, reviewing outputs, and shipping fast. This workflow demands tools that are **agent-first**: structured output, no interactive prompts, predictable behavior, and composability with other CLI tools.

Apple Maps has no official CLI interface. Developers who want to geocode an address, calculate an ETA, or search for nearby coffee shops must either write a full Swift app, use the paid Maps Server REST API, or manually construct `maps://` URLs. `applmaps` eliminates this gap by exposing MapKit's powerful non-UI capabilities as simple terminal commands.

The core design principles are:

- **JSON-first output** — every command returns structured JSON to stdout by default, with optional human-friendly formatting via `--format text`
- **Zero interactivity** — no prompts, no pagers, no spinners unless explicitly requested; agents should never block on stdin
- **Semantic exit codes** — `0` success, `1` user error, `2` network/API error, `3` no results found, enabling reliable agent branching logic
- **Unix composability** — pipe output to `jq`, chain with other tools, embed in shell scripts
- **Dual mode** — data commands (search, geocode, directions) return structured data; action commands (open, pin) control the Maps GUI app

---

## Technical architecture

### System design overview

`applmaps` is a **native macOS Swift CLI tool** that links against MapKit and CoreLocation frameworks. This is the optimal approach because MapKit's non-UI services — geocoding, local search, directions, and ETA calculation — all function without any graphical context, require **no API key**, and have no published hard rate limits for reasonable usage.

```
┌──────────────────────────────────────────────────┐
│                  applmaps CLI                     │
│  ┌──────────────┐  ┌──────────────────────────┐  │
│  │ ArgumentParser│  │   Output Formatter       │  │
│  │ (command      │  │  (JSON / Text / Table)   │  │
│  │  routing)     │  │                          │  │
│  └──────┬───────┘  └──────────┬───────────────┘  │
│         │                     │                   │
│  ┌──────▼─────────────────────▼───────────────┐  │
│  │           Command Handlers                  │  │
│  │  search │ directions │ geocode │ open │ eta │  │
│  └──────┬──────────┬──────────┬───────────────┘  │
│         │          │          │                   │
│  ┌──────▼──┐ ┌─────▼────┐ ┌──▼────────────┐     │
│  │MapKit   │ │CoreLoc.  │ │NSWorkspace    │     │
│  │MKLocal  │ │CLGeocoder│ │open(url:)     │     │
│  │Search   │ │          │ │maps:// URLs   │     │
│  │MKDirect.│ │          │ │               │     │
│  └─────────┘ └──────────┘ └───────────────┘     │
└──────────────────────────────────────────────────┘
          │              │              │
    Apple Maps      Apple Maps     Maps.app
    Servers         Servers        (GUI)
```

The architecture separates into three layers. The **parsing layer** uses Apple's `swift-argument-parser` for type-safe command routing. The **service layer** wraps MapKit and CoreLocation APIs with async/await. The **output layer** formats results as JSON (default), human-readable text, or tabular output.

### Why native MapKit over the REST API

| Factor | Native MapKit | Maps Server API |
|---|---|---|
| API key required | No | Yes (Apple Developer $99/yr) |
| Daily quota | No published limit | 25,000 calls/day |
| Auth complexity | None | JWT token generation + refresh |
| Platform | macOS only | Cross-platform |
| Transit directions | Yes | Yes |
| Cycling directions | Yes (WWDC 2025) | Limited |
| Setup complexity | `import MapKit` | Key management, token rotation |

For a macOS CLI tool, **native MapKit is the clear winner** — zero configuration, no cost, no rate limit concerns for typical usage. The Server API remains a future option for a potential cross-platform version or high-volume server deployment.

### Swift Package Manager configuration

```swift
// Package.swift
import PackageDescription

let package = Package(
    name: "applmaps",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0")
    ],
    targets: [
        .executableTarget(
            name: "applmaps",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "applmapsTests",
            dependencies: ["applmaps"]
        )
    ]
)
```

The tool requires **macOS 13+** (Ventura) for full async/await MapKit support and modern MKLocalSearch features. No Xcode project file is needed — `swift build` compiles directly. No entitlements are required for local development and direct distribution; the Maps entitlement is only needed for Mac App Store distribution.

---

## Apple Maps URL schemes — complete reference

The `open` command in `applmaps` constructs and dispatches these URLs via `NSWorkspace.shared.open()` or the shell `open` command. This is the **only reliable mechanism** for controlling the Maps.app GUI from the command line — Apple Maps has no AppleScript scripting dictionary and cannot be automated via `tell application`.

### Primary URL formats

Three base URL formats are supported, all using identical query parameters:

| Format | Behavior on macOS |
|---|---|
| `maps://?{params}` | Opens directly in Maps.app |
| `https://maps.apple.com/?{params}` | Opens in Maps.app (or Safari fallback) |
| `http://maps.apple.com/?{params}` | Same as HTTPS variant |

### Complete parameter reference

**Location and search parameters:**

| Parameter | Type | Description | Example |
|---|---|---|---|
| `q` | string | Search query or pin label. Treated as search input. Can also accept `lat,lon` to drop a pin. | `q=coffee+shops` or `q=37.78,-122.41` |
| `address` | string | Display a specific address (does NOT search). | `address=1+Infinite+Loop,Cupertino,CA` |
| `ll` | `lat,lon` | Center map at coordinates. Takes precedence over `address`. Does NOT drop a pin alone. | `ll=37.7749,-122.4194` |
| `near` | `lat,lon` | Hint location for search when `sll` is absent. | `near=40.7128,-74.0060` |
| `sll` | `lat,lon` | Bias search results toward this location. | `sll=37.78,-122.41` |

**Viewport control parameters:**

| Parameter | Type | Description | Example |
|---|---|---|---|
| `z` | float (2–21) | Zoom level. **Must be combined with `sll`**, not `ll`. | `z=14` |
| `spn` | `lat_delta,lon_delta` | Span of visible area around `ll`. Cannot combine with `z`. | `spn=0.05,0.05` |
| `sspn` | `lat_delta,lon_delta` | Search span around `sll`. | `sspn=0.01,0.01` |
| `t` | char | Map type: `m` = standard, `k` = satellite, `h` = hybrid | `t=k` |

**Directions parameters:**

| Parameter | Type | Description | Example |
|---|---|---|---|
| `daddr` | string or `lat,lon` | Destination address (**required** for directions). | `daddr=San+Francisco,CA` |
| `saddr` | string or `lat,lon` | Source address. Omit to use current location. | `saddr=Cupertino,CA` |
| `dirflg` | char | Transport mode: `d` = driving, `w` = walking, `r` = transit | `dirflg=r` |

**Place identification parameters** (used in shared/place URLs):

| Parameter | Type | Description |
|---|---|---|
| `auid` | numeric | Apple Unique Identifier for a specific place/POI |
| `place-id` | hex string | Newer hex-format place identifier (e.g., `I7C250D2CDCB364A`) |
| `lsp` | numeric | Location service provider type (commonly `9902`) |

### Known limitations of the URL scheme

The URL scheme **cannot** control: highway/toll avoidance, 3D mode or flyover tours, camera pitch or heading, Look Around, or multiple waypoints. There is no parameter for these features. The `dirflg=r` (transit) parameter may not work in all regions. Using `daddr` with raw coordinates has known bugs where Apple Maps may snap to a named entity rather than the exact coordinate — using addresses is more reliable for directions.

---

## Core features and command design

### Command hierarchy

```
applmaps
├── search       Search for places, businesses, and points of interest
├── directions   Calculate routes with turn-by-turn steps
├── eta          Get estimated travel time and distance (lightweight)
├── geocode      Convert address to coordinates
├── reverse      Convert coordinates to address (reverse geocode)
├── open         Open a location or search in Maps.app GUI
├── pin          Drop a pin at coordinates in Maps.app
└── config       Manage tool configuration
```

### Global flags

Every command accepts these flags, following agent-first CLI best practices:

| Flag | Short | Description |
|---|---|---|
| `--format <fmt>` | `-f` | Output format: `json` (default), `text`, `table` |
| `--quiet` | `-q` | Suppress non-essential output (progress, decorative text) |
| `--no-color` | | Disable colored output. Also respects `NO_COLOR` env var |
| `--fields <list>` | | Comma-separated list of fields to include in JSON output |
| `--pretty` | | Pretty-print JSON (default for TTY, compact for pipes) |
| `--version` | `-v` | Print version and exit |
| `--help` | `-h` | Print help and exit |

### Feature 1: `search` — local search and POI discovery

Wraps `MKLocalSearch` with `MKLocalSearch.Request`. Supports natural language queries, geographic biasing, POI category filtering, and result limiting.

```bash
# Basic search
applmaps search "coffee shops"

# Search near a location
applmaps search "pharmacies" --near "37.7749,-122.4194"

# Search with region constraint
applmaps search "restaurants" --near "40.7128,-74.0060" --radius 500

# Filter by POI category
applmaps search "food" --category cafe,restaurant --limit 5

# Human-readable output
applmaps search "gas stations" --near "37.33,-122.01" -f text
```

**Output schema (JSON):**
```json
{
  "query": "coffee shops",
  "region": { "center": { "lat": 37.7749, "lon": -122.4194 }, "radius_m": 1000 },
  "count": 3,
  "results": [
    {
      "name": "Blue Bottle Coffee",
      "coordinate": { "lat": 37.7825, "lon": -122.4092 },
      "address": {
        "street": "66 Mint St",
        "city": "San Francisco",
        "state": "CA",
        "zip": "94103",
        "country": "United States",
        "formatted": "66 Mint St, San Francisco, CA 94103"
      },
      "phone": "+1-510-653-3394",
      "url": "https://bluebottlecoffee.com",
      "category": "cafe",
      "timezone": "America/Los_Angeles",
      "maps_url": "maps://?q=Blue+Bottle+Coffee&ll=37.7825,-122.4092"
    }
  ]
}
```

### Feature 2: `directions` — route calculation with steps

Wraps `MKDirections` to calculate full routes including polylines, distances, travel times, and turn-by-turn text instructions.

```bash
# Driving directions between two addresses
applmaps directions --from "Cupertino, CA" --to "San Francisco, CA"

# Walking directions between coordinates
applmaps directions --from "37.33,-122.01" --to "37.78,-122.41" --mode walking

# Transit directions with alternate routes
applmaps directions --from "San Jose, CA" --to "San Francisco, CA" \
  --mode transit --alternatives

# Get directions and open in Maps.app
applmaps directions --from "home" --to "SFO Airport" --mode driving --open
```

**Output schema (JSON):**
```json
{
  "origin": { "name": "Cupertino, CA", "coordinate": { "lat": 37.323, "lon": -122.032 } },
  "destination": { "name": "San Francisco, CA", "coordinate": { "lat": 37.775, "lon": -122.418 } },
  "transport_type": "automobile",
  "routes": [
    {
      "name": "I-280 N",
      "distance_m": 72400,
      "distance_text": "45.0 mi",
      "duration_s": 2820,
      "duration_text": "47 min",
      "advisory_notices": [],
      "steps": [
        {
          "instruction": "Head north on De Anza Blvd",
          "distance_m": 450,
          "distance_text": "0.3 mi"
        },
        {
          "instruction": "Take the ramp onto I-280 N",
          "distance_m": 61200,
          "distance_text": "38.0 mi"
        }
      ]
    }
  ]
}
```

### Feature 3: `eta` — lightweight travel time estimates

Wraps `MKDirections.calculateETA()` for fast, traffic-aware travel time and distance without full route details. Supports **multiple destinations** in a single call.

```bash
# ETA from current concept to one destination
applmaps eta --from "Cupertino, CA" --to "San Francisco, CA"

# Multiple destinations
applmaps eta --from "37.33,-122.01" --to "SFO" --to "SJC" --to "OAK"

# Specific transport mode and departure time
applmaps eta --from "home" --to "work" --mode transit --depart "2025-03-01T08:00:00"
```

### Feature 4: `geocode` / `reverse` — coordinate conversion

Wraps `CLGeocoder` for forward and reverse geocoding.

```bash
# Forward geocode: address → coordinates
applmaps geocode "1 Apple Park Way, Cupertino, CA"

# Reverse geocode: coordinates → address
applmaps reverse 37.3349 -122.0090

# Batch geocode from stdin (one address per line)
cat addresses.txt | applmaps geocode --stdin
```

**Output schema (JSON):**
```json
{
  "query": "1 Apple Park Way, Cupertino, CA",
  "results": [
    {
      "coordinate": { "lat": 37.3349, "lon": -122.0090 },
      "address": {
        "street": "1 Apple Park Way",
        "city": "Cupertino",
        "state": "California",
        "zip": "95014",
        "country": "United States",
        "iso_country": "US",
        "formatted": "1 Apple Park Way, Cupertino, CA 95014, United States"
      },
      "timezone": "America/Los_Angeles",
      "areas_of_interest": ["Apple Park"]
    }
  ]
}
```

### Feature 5: `open` / `pin` — Maps.app GUI control

Constructs `maps://` URLs and dispatches them via `NSWorkspace` to control the Maps.app visual interface.

```bash
# Open Maps centered on a location
applmaps open --location "37.7749,-122.4194" --zoom 15

# Open search results in Maps
applmaps open --search "restaurants near Times Square"

# Open directions in Maps
applmaps open --directions --from "Cupertino" --to "SFO" --mode driving

# Drop a labeled pin
applmaps pin 37.7749 -122.4194 --label "Meeting Point"

# Open with satellite view
applmaps open --search "Grand Canyon" --map-type satellite
```

These commands return the constructed URL in the JSON output, enabling agents to verify what was dispatched:

```json
{
  "action": "open",
  "url": "maps://?q=restaurants+near+Times+Square",
  "opened": true
}
```

---

## Data models and internal API

### Core types

```swift
// MARK: - Coordinate
struct Coordinate: Codable, CustomStringConvertible {
    let lat: Double
    let lon: Double
    
    var description: String { "\(lat),\(lon)" }
    var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    /// Parse from "lat,lon" string
    init?(string: String) { /* ... */ }
}

// MARK: - Address
struct Address: Codable {
    let street: String?
    let city: String?
    let state: String?
    let zip: String?
    let country: String?
    let isoCountry: String?
    let formatted: String
    
    init(from placemark: CLPlacemark) { /* map CLPlacemark fields */ }
}

// MARK: - Place (search result)
struct Place: Codable {
    let name: String
    let coordinate: Coordinate
    let address: Address
    let phone: String?
    let url: String?
    let category: String?
    let timezone: String?
    let mapsURL: String  // constructed maps:// URL
}

// MARK: - Route
struct Route: Codable {
    let name: String
    let distanceMeters: Double
    let distanceText: String
    let durationSeconds: Double
    let durationText: String
    let advisoryNotices: [String]
    let steps: [RouteStep]
}

struct RouteStep: Codable {
    let instruction: String
    let distanceMeters: Double
    let distanceText: String
}

// MARK: - ETA
struct ETAResult: Codable {
    let destination: String
    let coordinate: Coordinate
    let transportType: String
    let distanceMeters: Double
    let distanceText: String
    let travelTimeSeconds: Double
    let travelTimeText: String
    let expectedArrival: String?  // ISO 8601
}
```

### Service layer

```swift
// MARK: - MapService protocol (for testability)
protocol MapService {
    func search(query: String, near: Coordinate?, radius: Double?,
                categories: [String]?, limit: Int?) async throws -> [Place]
    func directions(from: String, to: String, mode: TransportMode,
                    alternatives: Bool) async throws -> [Route]
    func eta(from: String, to: [String], mode: TransportMode,
             departureDate: Date?) async throws -> [ETAResult]
    func geocode(address: String) async throws -> [GeocodingResult]
    func reverseGeocode(coordinate: Coordinate) async throws -> [GeocodingResult]
}

// MARK: - MapKitService (concrete implementation)
final class MapKitService: MapService {
    func search(query: String, near: Coordinate?, radius: Double?,
                categories: [String]?, limit: Int?) async throws -> [Place] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        if let near = near {
            let span = radius.map { MKCoordinateSpan(
                latitudeDelta: $0 / 111_000,
                longitudeDelta: $0 / 111_000
            ) } ?? MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            request.region = MKCoordinateRegion(center: near.clLocationCoordinate2D, span: span)
        }
        if let categories = categories {
            request.pointOfInterestFilter = MKPointOfInterestFilter(
                including: categories.compactMap { MKPointOfInterestCategory(rawValue: $0) }
            )
        }
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        return response.mapItems.prefix(limit ?? 10).map { Place(from: $0) }
    }
    // ... other methods follow same pattern
}
```

### Output formatting

```swift
enum OutputFormat: String, ExpressibleByArgument {
    case json, text, table
}

struct OutputFormatter {
    let format: OutputFormat
    let pretty: Bool
    let fields: [String]?
    
    func render<T: Encodable>(_ value: T) throws -> String {
        switch format {
        case .json:
            let encoder = JSONEncoder()
            encoder.outputFormatting = pretty ? [.prettyPrinted, .sortedKeys] : .sortedKeys
            let data = try encoder.encode(value)
            return String(data: data, encoding: .utf8)!
        case .text:
            return renderText(value)  // Human-friendly formatting
        case .table:
            return renderTable(value) // Columnar output
        }
    }
}
```

---

## Implementation approach — Swift CLI with ArgumentParser

### Entry point structure

```swift
import ArgumentParser

@main
struct ApplMaps: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "applmaps",
        abstract: "Apple Maps from the command line — agent-first.",
        version: "0.1.0",
        subcommands: [
            Search.self,
            Directions.self,
            ETA.self,
            Geocode.self,
            Reverse.self,
            Open.self,
            Pin.self,
            Config.self
        ]
    )
}
```

Each subcommand conforms to `AsyncParsableCommand` since all MapKit operations are network-based and asynchronous. The `async/await` pattern integrates cleanly with ArgumentParser's `AsyncParsableCommand` protocol and avoids semaphore/RunLoop complexity.

### Build and distribution

The tool compiles to a single static binary via `swift build -c release`. Distribution options include Homebrew tap (`brew install steipete/tap/applmaps`), direct download of the universal binary (arm64 + x86_64 via `lipo`), or Mint (`mint install steipete/applmaps`). No code signing or notarization is strictly required for developer tools distributed outside the App Store, though notarization is recommended for broader distribution.

---

## Agent integration patterns

### MCP (Model Context Protocol) server mode

`applmaps` can double as an MCP server for direct AI agent integration. Running `applmaps mcp` starts a stdio-based MCP server that exposes each command as a typed tool:

```json
{
  "tools": [
    {
      "name": "search_places",
      "description": "Search for places, businesses, and POIs using Apple Maps",
      "inputSchema": {
        "type": "object",
        "properties": {
          "query": { "type": "string", "description": "Natural language search query" },
          "near": { "type": "string", "description": "Coordinates as 'lat,lon' to bias results" },
          "radius": { "type": "number", "description": "Search radius in meters" },
          "limit": { "type": "integer", "description": "Max results (default 10)" }
        },
        "required": ["query"]
      }
    },
    {
      "name": "get_directions",
      "description": "Calculate route with turn-by-turn directions between two locations"
    },
    {
      "name": "get_eta",
      "description": "Get estimated travel time and distance to one or more destinations"
    },
    {
      "name": "geocode_address",
      "description": "Convert a street address to geographic coordinates"
    },
    {
      "name": "open_in_maps",
      "description": "Open a location, search, or directions in the Apple Maps GUI app"
    }
  ]
}
```

This allows Claude, GPT, and other LLM agents to discover and call `applmaps` capabilities dynamically without pre-programmed knowledge of the CLI syntax.

### Composability examples for agent workflows

```bash
# Agent: "Find the nearest coffee shop and get walking directions"
SHOP=$(applmaps search "coffee" --near "37.78,-122.41" --limit 1 | jq -r '.results[0].coordinate | "\(.lat),\(.lon)"')
applmaps directions --from "37.78,-122.41" --to "$SHOP" --mode walking

# Agent: "What's the ETA to all three airports from my hotel?"
applmaps eta --from "Union Square, SF" --to "SFO" --to "OAK" --to "SJC" | jq '.results[] | {dest: .destination, time: .travelTimeText}'

# Agent: "Geocode this list of addresses and find the centroid"
cat addresses.txt | applmaps geocode --stdin | jq '[.results[].coordinate] | {lat: (map(.lat) | add / length), lon: (map(.lon) | add / length)}'

# Agent: "Show me this route on the map"
applmaps open --directions --from "Cupertino" --to "Palo Alto" --mode cycling --map-type satellite
```

---

## Technical considerations and limitations

### MapKit constraints in CLI context

**What works without a UI:** Geocoding (forward and reverse), local search with natural language queries and POI filtering, full route calculation with turn-by-turn text, ETA calculation with traffic awareness, and search autocompletion. **What does NOT work:** Map rendering, annotations/overlays display, Look Around imagery, and any visual feature. These are GUI-only and can only be triggered via `maps://` URL dispatch to Maps.app.

**Rate limiting** is implicit. CLGeocoder documentation recommends one request at a time per geocoder instance. MKLocalSearch and MKDirections may return `MKError.loadingThrottled` under heavy load, but no hard published limits exist. The tool should implement automatic retry with exponential backoff for throttled responses, and sequential processing for geocoding batch operations.

### Maps.app control limitations

Apple Maps has **no AppleScript scripting dictionary**. The tool cannot read state from Maps.app (current view, search results, selected place), cannot programmatically interact with the UI beyond what URL parameters allow, and cannot extract data from the Maps GUI. The `open` and `pin` commands are fire-and-forget — they dispatch a URL and cannot confirm what Maps.app actually displayed.

UI scripting via System Events (`tell application "System Events" to tell process "Maps"`) is technically possible but extremely fragile across macOS versions, requires Accessibility permissions, and is not recommended for any reliable automation.

### Platform and version requirements

The tool requires **macOS 13 (Ventura) or later** for full async/await MapKit support, modern MKLocalSearch result types, and MKLocalPointsOfInterestRequest. Cycling directions require **macOS 26** (from WWDC 2025). The tool should gracefully degrade on older macOS versions by catching unsupported transport type errors and returning a clear error message.

### Privacy and location access

`MKMapItem.forCurrentLocation()` requires location services permission. The CLI tool should support a `--current-location` flag but clearly document that the first invocation will trigger a macOS location permission dialog. For agent-first usage, explicit coordinates are preferred over current-location to avoid blocking on permission prompts.

---

## Development roadmap

### Phase 1: Core data commands (weeks 1–2)

Deliver `geocode`, `reverse`, `search`, and `eta` commands with full JSON output, the OutputFormatter infrastructure, and comprehensive error handling. This phase establishes the project skeleton, CI with `swift test`, and a Homebrew formula. These four commands cover the highest-value agent use cases — **answering questions about places**.

### Phase 2: Directions and Maps.app control (weeks 3–4)

Add `directions` with full turn-by-turn step output, `open` and `pin` commands for GUI dispatch, and `--open` flags on data commands that both return structured data and open Maps.app. This phase also implements the `--stdin` batch mode for geocoding.

### Phase 3: Agent integration (weeks 5–6)

Build the MCP server mode (`applmaps mcp`) for native LLM agent integration, add shell completion generation for zsh/bash/fish, implement `applmaps --json-schema` that dumps the full input/output schema for all commands (enabling agent self-discovery), and add a `--fields` flag for selective JSON output following the GitHub CLI pattern.

### Phase 4: Advanced features (weeks 7–8)

Add search autocompletion (`applmaps complete "star"`), POI category listing (`applmaps categories`), support for the Apple Maps Server REST API as an alternative backend (`--backend server`), and the Maps Web Snapshot URL generator for producing static map images. This phase also explores Apple's newer unified Maps URL format (introduced in iOS 18.4) for richer `open` commands.

---

## Conclusion

`applmaps` fills a genuine gap in the macOS developer toolchain. The fact that MapKit's most valuable services — search, geocoding, directions, ETAs — all work without any UI context makes a native Swift CLI tool both practical and powerful. By defaulting to JSON output, supporting MCP, and following agent-first design patterns, the tool slots naturally into the AI-augmented development workflows that are becoming standard. The technical risk is low: the underlying MapKit APIs are mature, well-documented, and free to use. The primary constraint is macOS-only execution, which is acceptable given the target audience of Apple developers and macOS-native AI coding agent setups.