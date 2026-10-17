---
name: applemaps
type: AgentSkill
compatible_with: OpenClaw
entrypoint: applemaps
description: Search places, plan multistop journeys and open Apple Maps using the local `applemaps` CLI on macOS.
version: 1.0.0
platform: macOS
---

# AppleMapsCLI AgentSkill for OpenClaw

This skill enables OpenClaw agents to use the `applemaps` CLI for Apple Maps search, geocoding, routing, URL opening, and category discovery.

## Scope

- Local CLI execution only.
- No MCP server mode.
- No web API mode.
- JSON-first output for machine consumption.

## Capabilities

| Intent | Command |
| --- | --- |
| Forward geocode an address | `applemaps geocode "<address>"` |
| Reverse geocode coordinates | `applemaps reverse <lat> <lon>` |
| Search for places | `applemaps search "<query>"` |
| Autocomplete query text | `applemaps complete "<partial>"` |
| Get route directions (optional multiple stops) | `applemaps directions --from "<origin>" --via "<stop>" --to "<destination>"` |
| Get ETA for one or more destinations | `applemaps eta --from "<origin>" --to "<destination>" [--to "..."]` |
| Open Apple Maps URL modes | `applemaps open ...` |
| Drop a pin in Maps | `applemaps pin <lat> <lon> [--label "..."]` |
| List POI categories | `applemaps categories [--format json|text|table]` |
| Generate shell completions | `applemaps completions zsh|bash|fish` |

## Output and Exit Contract

- Default stdout format: JSON.
- `--pretty`: force pretty JSON.
- `--fields a,b,c`: JSON projection (JSON output only).
- `--json-schema`: emit input/output schema instead of running command logic.

Semantic exit codes:

- `0` success
- `1` user error (validation, invalid args, unsupported format, etc.)
- `2` network or API error (MapKit/CoreLocation or system execution failures)
- `3` no results

## Agent Execution Rules

1. Choose one command that matches user intent.
2. Prefer JSON output unless user explicitly requests text or table.
3. Use `--json-schema` when building strongly typed integrations.
4. Treat location data as sensitive; avoid echoing full location history.
5. Handle non-zero exits semantically:
   - `1`: fix arguments.
   - `2`: retry later or report upstream dependency issue.
   - `3`: report no matches without retry loops.

## Common Patterns

### Geocode and reverse geocode

```bash
applemaps geocode "1 Apple Park Way, Cupertino, CA"
applemaps reverse 37.3349 -122.0090
```

### Batch geocode from stdin

```bash
printf "New York, NY\nSeattle, WA\n" | applemaps geocode --stdin
```

### Search and autocomplete

```bash
applemaps search "coffee" --near "37.7749,-122.4194" --radius 1500 --limit 5
applemaps complete "star" --limit 10
```

### Directions and ETA

```bash
applemaps directions --from "San Francisco, CA" --to "San Jose, CA" --mode driving
applemaps directions --from "北京" --via "洛阳" --via "芜湖" --via "杭州" --to "上海" --mode driving
applemaps eta --from "San Francisco, CA" --to "Oakland, CA" --to "Berkeley, CA"
```

Supported transport modes:

- `driving`
- `walking`
- `transit`
- `cycling`

### Open and pin

```bash
applemaps open --search "coffee near Union Square"
applemaps open --location "37.3349,-122.0090" --zoom 15
applemaps open --from "San Francisco, CA" --to "San Jose, CA" --mode transit
applemaps open --from "北京" --via "洛阳" --via "芜湖" --via "杭州" --to "上海" --mode driving
applemaps pin 37.3349 -122.0090 --label "Apple Park"
```

### Categories and completions

```bash
applemaps categories --format table
applemaps completions zsh
```

## Integration Notes for OpenClaw

- Parse stdout as JSON by default.
- Read stderr for actionable diagnostics.
- For reverse and pin, prefer separate numeric latitude/longitude tokens:
  - `applemaps reverse 37.3349 -122.0090`
  - `applemaps pin 37.3349 -122.0090`
- For schema-driven agents, start with:
  - `applemaps <command> --json-schema`
