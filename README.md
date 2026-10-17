# AppleMapsCLI

Native Apple Maps CLI for macOS, built with Swift 6. The executable is `applemaps`.

Forked from [rastreus/applmaps](https://github.com/rastreus/applmaps) under the MIT license; this fork adds ordered multi-stop routes.

`applemaps` provides scriptable access to Apple Maps capabilities including geocoding, reverse geocoding, search, autocomplete, directions, ETA, URL opening, pin dropping, and POI category listing.

## Status

- Free to use with native MapKit; no API key or separate paid mapping service required.
- CLI-first tool with JSON output by default.
- No built-in telemetry.
- No MCP server mode.
- No web API mode.

## Requirements

- macOS 15.6 or later, Apple Silicon (arm64)
- Xcode 26 or later (Swift 6.2+, MapKit cycling API) **only when building from source**. Xcode 26 requires macOS 15.6+ on the build machine.

## Install

```bash
brew install chiimagnus/tap/applemapscli
applemaps --help
```

GitHub Releases distribute one precompiled Apple Silicon binary. See [release and Homebrew details](docs/release.md).

## Build

```bash
git clone https://github.com/chiimagnus/AppleMapsCLI.git
cd AppleMapsCLI
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
.build/debug/applemaps --help
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
.build/debug/applemaps geocode "1 Apple Park Way, Cupertino, CA"
.build/debug/applemaps reverse 37.3349 -122.0090
```

### Batch geocode from stdin

```bash
printf "Seattle, WA\nPortland, OR\n" | .build/debug/applemaps geocode --stdin
```

### Search and autocomplete

```bash
.build/debug/applemaps search "coffee" --near "37.7749,-122.4194" --radius 1500 --limit 5
.build/debug/applemaps complete "star" --limit 10
```

### Directions and ETA

```bash
.build/debug/applemaps directions --from "San Francisco, CA" --to "San Jose, CA" --mode driving
.build/debug/applemaps eta --from "San Francisco, CA" --to "Oakland, CA" --to "Berkeley, CA"
```

### Multistop road trip

Use `--via` multiple times to keep intermediate stops in the requested order:

```bash
.build/debug/applemaps directions \
  --from "北京市" --via "洛阳市" --via "芜湖市" \
  --via "杭州市" --to "上海市" --mode driving \
  > trip.json

.build/debug/applemaps open \
  --from "北京市" --via "洛阳市" --via "芜湖市" \
  --via "杭州市" --to "上海市" --mode driving
```

- `directions --via` asks MapKit for each **adjacent pair** in sequence and returns `legs`, `total_distance_m`, and `total_duration_s`. Totals sum the first suggested route for each leg; they do not represent one continuous MapKit route. Without `--via`, existing single-route JSON remains unchanged.
- `open --via` uses Apple's unified multistop Maps URL. It **opens the route request**, but Maps may display "Route Not Available" even when it correctly lists all the stops. URL dispatch success is not proof of navigation availability.
- Apple Maps may calculate the trip after stops are added manually one by one, but this tool does not script the Maps UI or save to its private route database. Save the JSON to a local file as shown above.
- No API key, paid routing provider, background service, or telemetry is required.

### Open and pin

```bash
.build/debug/applemaps open --search "coffee near Union Square"
.build/debug/applemaps open --location "37.3349,-122.0090" --zoom 15
.build/debug/applemaps pin 37.3349 -122.0090 --label "Apple Park"
```

### Categories and shell completions

```bash
.build/debug/applemaps categories --format table
.build/debug/applemaps completions zsh
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

## Install from source (optional)

```bash
swift build -c release
mkdir -p ~/.local/bin
install -m 755 .build/release/applemaps ~/.local/bin/applemaps
```

## Development Notes

- Source layout:
  - `Sources/AppleMapsCLI/Utilities`
  - `Sources/AppleMapsCLI/Core`
  - `Sources/AppleMapsCLI/Output`
  - `Sources/AppleMapsCLI/Commands`
- Tests use Swift Testing (`import Testing`).
- See `AGENTS.md` for architecture and project constraints.
- See `docs/SKILL.md` for OpenClaw AgentSkill guidance.
- See [CONTRIBUTING.md](CONTRIBUTING.md) for Issue, PR and testing guidelines.
