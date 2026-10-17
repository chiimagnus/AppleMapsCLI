# applmaps

Agent-first Apple Maps CLI for macOS, built with Swift 6.

`applmaps` provides scriptable access to Apple Maps capabilities including geocoding, reverse geocoding, search, autocomplete, directions, ETA, URL opening, pin dropping, and POI category listing.

## Status

- CLI-first tool with JSON output by default.
- No MCP server mode.
- No web API mode.

## Requirements

- macOS 13 or later (`open --via` requires macOS 15.4+)
- Xcode with Swift 6 toolchain

## Build

```bash
swift build
```

If you are in a restricted sandbox:

```bash
swift build --disable-sandbox
```

## Test

```bash
swift test
```

If you are in a restricted sandbox:

```bash
swift test --disable-sandbox
```

## Run

```bash
.build/debug/applmaps --help
```

## Commands

```text
geocode      Convert an address into geographic coordinates
reverse      Convert latitude and longitude into a formatted address
search       Search for places and points of interest
complete     Return autocomplete suggestions for a partial search query
directions   Get route directions with turn-by-turn steps
eta          Get travel time estimates to one or more destinations
open         Construct and open Apple Maps URLs
pin          Drop a pin at a coordinate with an optional label
categories   List supported MapKit point-of-interest categories
completions  Generate shell completion scripts (zsh, bash, fish)
```

## Quick Examples

### Geocode and reverse

```bash
.build/debug/applmaps geocode "1 Apple Park Way, Cupertino, CA"
.build/debug/applmaps reverse 37.3349 -122.0090
```

### Batch geocode from stdin

```bash
printf "Seattle, WA\nPortland, OR\n" | .build/debug/applmaps geocode --stdin
```

### Search and autocomplete

```bash
.build/debug/applmaps search "coffee" --near "37.7749,-122.4194" --radius 1500 --limit 5
.build/debug/applmaps complete "star" --limit 10
```

### Directions and ETA

```bash
.build/debug/applmaps directions --from "San Francisco, CA" --to "San Jose, CA" --mode driving
.build/debug/applmaps eta --from "San Francisco, CA" --to "Oakland, CA" --to "Berkeley, CA"
```

### Multistop road trip

Use `--via` multiple times to keep intermediate stops in the requested order:

```bash
.build/debug/applmaps directions \
  --from "北京市" --via "洛阳市" --via "芜湖市" \
  --via "杭州市" --to "上海市" --mode driving \
  > trip.json

.build/debug/applmaps open \
  --from "北京市" --via "洛阳市" --via "芜湖市" \
  --via "杭州市" --to "上海市" --mode driving
```

- `directions --via` asks MapKit for each **adjacent pair** in sequence and returns `legs`, `total_distance_m`, and `total_duration_s`. Totals sum the first suggested route for each leg; they do not represent one continuous MapKit route. Without `--via`, existing single-route JSON remains unchanged.
- `open --via` uses Apple's unified multistop Maps URL (macOS 15.4+). It **opens the route request**, but Maps may display "Route Not Available" even when it correctly lists all the stops. URL dispatch success is not proof of navigation availability.
- Apple Maps may calculate the trip after stops are added manually one by one, but this tool does not script the Maps UI or save to its private route database. Save the JSON to a local file as shown above.
- No API key, paid routing provider, background service, or telemetry is required.

### Open and pin

```bash
.build/debug/applmaps open --search "coffee near Union Square"
.build/debug/applmaps open --location "37.3349,-122.0090" --zoom 15
.build/debug/applmaps pin 37.3349 -122.0090 --label "Apple Park"
```

### Categories and shell completions

```bash
.build/debug/applmaps categories --format table
.build/debug/applmaps completions zsh
```

## Output Contract

- Default format is JSON.
- `--pretty` forces pretty-printed JSON.
- `--fields` projects JSON fields.
- `--json-schema` prints command input/output JSON schema.
- `categories` also supports `--format text` and `--format table`.

Stdout contains result payloads. Stderr contains diagnostics and errors.

## Exit Codes

- `0` success
- `1` user error
- `2` network or API error
- `3` no results

## Transport Modes

Where supported (`directions`, `eta`, `open`):

- `driving`
- `walking`
- `transit`
- `cycling`

## Install (optional)

```bash
swift build -c release
cp .build/release/applmaps /usr/local/bin/applmaps
```

## Development Notes

- Source layout:
  - `Sources/applmaps/Utilities`
  - `Sources/applmaps/Core`
  - `Sources/applmaps/Output`
  - `Sources/applmaps/Commands`
- Tests use Swift Testing (`import Testing`).
- See `AGENTS.md` for architecture and project constraints.
- See `docs/SKILL.md` for OpenClaw AgentSkill guidance.
