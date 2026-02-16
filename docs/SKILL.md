---
name: applmaps
type: AgentSkill
compatible_with: OpenClaw
entrypoint: applmaps
version: 1.0.0
platform: macOS
---

# applmaps AgentSkill for OpenClaw

This skill enables OpenClaw agents to use the `applmaps` CLI for Apple Maps search, geocoding, routing, URL opening, and category discovery.

## Scope

- Local CLI execution only.
- No MCP server mode.
- No web API mode.
- JSON-first output for machine consumption.

## Capabilities

| Intent | Command |
| --- | --- |
| Forward geocode an address | `applmaps geocode "<address>"` |
| Reverse geocode coordinates | `applmaps reverse <lat> <lon>` |
| Search for places | `applmaps search "<query>"` |
| Autocomplete query text | `applmaps complete "<partial>"` |
| Get route directions | `applmaps directions --from "<origin>" --to "<destination>"` |
| Get ETA for one or more destinations | `applmaps eta --from "<origin>" --to "<destination>" [--to "..."]` |
| Open Apple Maps URL modes | `applmaps open ...` |
| Drop a pin in Maps | `applmaps pin <lat> <lon> [--label "..."]` |
| List POI categories | `applmaps categories [--format json|text|table]` |
| Generate shell completions | `applmaps completions zsh|bash|fish` |

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
applmaps geocode "1 Apple Park Way, Cupertino, CA"
applmaps reverse 37.3349 -122.0090
```

### Batch geocode from stdin

```bash
printf "New York, NY\nSeattle, WA\n" | applmaps geocode --stdin
```

### Search and autocomplete

```bash
applmaps search "coffee" --near "37.7749,-122.4194" --radius 1500 --limit 5
applmaps complete "star" --limit 10
```

### Directions and ETA

```bash
applmaps directions --from "San Francisco, CA" --to "San Jose, CA" --mode driving
applmaps eta --from "San Francisco, CA" --to "Oakland, CA" --to "Berkeley, CA"
```

Supported transport modes:

- `driving`
- `walking`
- `transit`
- `cycling`

### Open and pin

```bash
applmaps open --search "coffee near Union Square"
applmaps open --location "37.3349,-122.0090" --zoom 15
applmaps open --from "San Francisco, CA" --to "San Jose, CA" --mode transit
applmaps pin 37.3349 -122.0090 --label "Apple Park"
```

### Categories and completions

```bash
applmaps categories --format table
applmaps completions zsh
```

## Integration Notes for OpenClaw

- Parse stdout as JSON by default.
- Read stderr for actionable diagnostics.
- For reverse and pin, prefer separate numeric latitude/longitude tokens:
  - `applmaps reverse 37.3349 -122.0090`
  - `applmaps pin 37.3349 -122.0090`
- For schema-driven agents, start with:
  - `applmaps <command> --json-schema`
