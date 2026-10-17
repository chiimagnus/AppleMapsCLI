# Product Requirements Document: AppleMapsCLI (`applemaps`)

**Version:** 1.0  
**Date:** 2025-02-15  
**Status:** Draft  
**Owner:** Engineering Team

---

## Executive Summary

`applemaps` is a native macOS command-line tool that provides programmatic access to Apple Maps services. It wraps MapKit's non-UI APIs (search, geocoding, directions, ETA calculation) and the `maps://` URL scheme to give developers and AI coding agents structured, machine-readable access to Apple Maps without opening Xcode or launching a GUI application.

### Problem Statement

Developers and AI agents working on macOS need to:
- Geocode addresses and reverse-geocode coordinates programmatically
- Search for places and points of interest from scripts
- Calculate routes and travel times for automation tasks
- Open Apple Maps at specific locations or with specific searches

Currently, there is no official Apple-provided CLI for these tasks. Developers must either:
1. Write full Swift applications to use MapKit
2. Pay for the Maps Server REST API ($99/year + quota limits)
3. Manually construct `maps://` URLs without proper documentation
4. Use third-party geocoding services that don't match Apple's data

### Solution

A Swift 6 CLI tool that exposes MapKit capabilities through simple, composable commands with JSON-first output. The tool follows agent-first design principles:
- Machine-readable JSON output by default
- Zero interactivity (no prompts or spinners)
- Semantic exit codes for programmatic handling
- Unix-composable with pipes and other CLI tools

---

## User Personas

### Primary Persona: AI Coding Agent
**Description:** LLM-powered development assistants (Claude, GPT-4, etc.) that generate code, automate tasks, and process data through CLI tools.

**Needs:**
- Structured, parseable output (JSON)
- Deterministic behavior without user interaction
- Clear error messages with actionable context
- Ability to discover capabilities programmatically

**Use Cases:**
- Geocoding lists of addresses from a CSV
- Finding nearby businesses for app development
- Calculating ETAs for route optimization scripts
- Opening Maps at specific locations for user workflows

### Secondary Persona: Developer/Scripter
**Description:** macOS developers and power users who automate workflows with shell scripts, Python, or other languages.

**Needs:**
- Fast, local geocoding without API keys
- Reliable place search for prototyping
- Ability to chain with other CLI tools (jq, awk, etc.)
- Human-readable output option for debugging

**Use Cases:**
- Geocoding addresses in migration scripts
- Building location-based prototypes
- Automating driving directions for logistics
- Integration testing for mapping features

### Tertiary Persona: MCP Server Operator
**Description:** Users running Model Context Protocol servers to give LLMs access to local system capabilities.

**Needs:**
- Native MCP server mode for direct LLM integration
- Tool schemas that LLMs can discover and use
- Structured input/output for tool calling

**Use Cases:**
- Enabling Claude Desktop to search for places
- Giving AI assistants geocoding capabilities
- Allowing agents to open Maps with specific queries

---

## Core Features

### F1: Place Search (`search` command)
**Priority:** P0 (MVP)

Search for places, businesses, and points of interest using natural language queries.

**Requirements:**
- Accept natural language search queries (e.g., "coffee shops", "restaurants near Times Square")
- Support geographic biasing with `--near lat,lon`
- Support radius constraints with `--radius meters`
- Filter by POI categories (cafe, restaurant, hotel, etc.)
- Limit results with `--limit N`
- Return structured JSON with name, address, coordinates, phone, URL, category

**Acceptance Criteria:**
- `applemaps search "coffee"` returns ≤10 results as JSON
- `applemaps search "pizza" --near "37.78,-122.41" --radius 500` returns results within 500m
- Results include all documented fields (name, coordinate, address, etc.)
- Invalid coordinates return exit code 1
- Network errors return exit code 2
- Zero results return exit code 3

---

### F2: Geocoding (`geocode` / `reverse` commands)
**Priority:** P0 (MVP)

Convert between addresses and coordinates using Apple's geocoding service.

**Requirements:**
- `geocode`: Convert street addresses to coordinates
- `reverse`: Convert coordinates to addresses
- Support batch processing via `--stdin` (one address per line)
- Handle ambiguous addresses (return multiple results)
- Return timezone, ISO country code, formatted address
- Process geocode batches sequentially (respect CLGeocoder guidance)

**Acceptance Criteria:**
- `applemaps geocode "1 Apple Park Way, Cupertino"` returns coordinates
- `applemaps reverse 37.3349 -122.0090` returns formatted address
- `cat addresses.txt | applemaps geocode --stdin` processes all addresses
- Batch mode processes sequentially (no parallel CLGeocoder instances)
- Invalid addresses return exit code 3 (no results)

---

### F3: Directions (`directions` command)
**Priority:** P0 (MVP)

Calculate routes with turn-by-turn instructions between two locations.

**Requirements:**
- Support addresses and coordinates as origin/destination
- Transport modes: driving (default), walking, transit, cycling
- Return route name, total distance, total duration
- Include turn-by-turn text instructions with per-step distances
- Support `--alternatives` flag for multiple route options
- Optional `--open` flag to also open route in Maps.app GUI

**Acceptance Criteria:**
- `applemaps directions --from "Cupertino" --to "San Francisco"` returns route JSON
- `--mode walking` calculates pedestrian route
- `--alternatives` returns 2-3 route options when available
- Steps array includes instruction text and distance for each turn
- Invalid transport mode for region returns exit code 2 with clear message

---

### F4: ETA Calculation (`eta` command)
**Priority:** P1 (Phase 1)

Get estimated travel time and distance without full route details.

**Requirements:**
- Lightweight alternative to full `directions` command
- Support multiple destinations in single call (`--to` can be repeated)
- Include traffic-aware travel time estimates
- Return expected arrival time (ISO 8601) if departure time specified
- Transport mode support (driving, walking, transit)

**Acceptance Criteria:**
- `applemaps eta --from "SF" --to "Oakland"` returns travel time in seconds + text
- `applemaps eta --from "home" --to "SFO" --to "OAK" --to "SJC"` returns all three ETAs
- Travel time reflects current traffic conditions
- JSON includes both numeric (seconds) and human-readable (text) formats

---

### F5: Maps.app GUI Control (`open` / `pin` commands)
**Priority:** P1 (Phase 2)

Control the Apple Maps graphical application via URL scheme.

**Requirements:**
- `open`: Open Maps with search, location, or directions
- `pin`: Drop a labeled pin at coordinates
- Support map type selection (standard, satellite, hybrid)
- Support zoom level specification
- Construct proper `maps://` URLs with all parameters
- Return constructed URL in JSON output for verification

**Acceptance Criteria:**
- `applemaps open --search "coffee"` opens Maps with search results
- `applemaps open --location "37.78,-122.41" --zoom 15` centers map at location
- `applemaps pin 37.78 -122.41 --label "Meeting Point"` drops labeled pin
- `applemaps open --directions --from "SF" --to "Oakland" --mode transit` opens route
- Commands return immediately (don't block waiting for Maps)

---

### F6: JSON-First Output with Formatting Options
**Priority:** P0 (MVP)

Default to machine-readable JSON; support human-friendly formats.

**Requirements:**
- JSON output to stdout by default (compact when piped)
- `--format text`: Human-readable prose output
- `--format table`: Columnar output for results
- `--pretty`: Force pretty-printed JSON (even when piped)
- `--fields a,b,c`: Project only specified JSON fields
- `--quiet`: Suppress non-essential stderr output
- TTY detection: auto-pretty for terminal, compact for pipes

**Acceptance Criteria:**
- Default output is valid, parseable JSON
- `applemaps search "coffee" | jq '.results[0].name'` works
- `applemaps search "coffee" --format text` produces readable prose
- `--fields name,coordinate` returns only those fields in JSON
- isatty check: pretty JSON when outputting to terminal directly

---

### F7: Semantic Exit Codes
**Priority:** P0 (MVP)

Programmatic error handling through consistent exit codes.

**Requirements:**
- Exit 0: Success
- Exit 1: User error (invalid args, bad coordinates, parse failures)
- Exit 2: Network/API error (MapKit failures, throttling)
- Exit 3: No results found (empty search/geocode)

**Acceptance Criteria:**
- `applemaps geocode "invalid garbage" || echo $?` prints "3"
- Invalid flag usage exits with code 1
- Network timeouts exit with code 2
- All commands respect exit code contract

---

## Non-Functional Requirements

### Performance
- Geocode operations: < 2s for single address (network dependent)
- Search operations: < 3s for typical query (network dependent)
- JSON encoding: < 100ms for typical result set
- Command startup: < 200ms (Swift executable overhead)

### Reliability
- Handle MapKit rate limiting with exponential backoff (1s, 2s, 4s)
- Gracefully degrade unsupported features on older macOS versions
- Never crash on malformed input (return exit code 1)
- Retry transient network errors (3 attempts max)

### Security & Privacy
- Never log coordinates, addresses, or search queries to stdout by default
- Verbose logging (`--verbose`) may log to stderr for debugging
- No persistent storage of location data
- No telemetry or analytics
- Current location (`--current-location`) requires explicit flag + documents permission dialog

### Compatibility
- macOS 13 (Ventura) minimum for async/await MapKit
- macOS 14+ for cycling directions (graceful degradation)
- Swift 6.0+ with strict concurrency
- No API keys required (uses local MapKit)

---

## User Stories (Implementation Phases)

### Phase 1: Core Data Commands

**S01: As a developer, I want to geocode addresses so I can get coordinates for my dataset**
- Implement `geocode` command with single address input
- Return JSON with coordinate, formatted address, timezone
- Handle "no results" with exit code 3
- Acceptance: `applemaps geocode "Apple Park"` returns valid JSON

**S02: As a scripter, I want to reverse geocode coordinates so I can display human-readable locations**
- Implement `reverse` command accepting lat/lon arguments
- Return Address object with all fields
- Acceptance: `applemaps reverse 37.33 -122.01` returns address

**S03: As an agent, I want to search for nearby places so I can find businesses programmatically**
- Implement `search` command with query + optional `--near` and `--radius`
- Return array of Place objects with all documented fields
- Acceptance: `applemaps search "restaurants" --near "40.71,-74.00" --limit 5`

**S04: As a scripter, I want to get travel time estimates so I can optimize routes**
- Implement `eta` command with from/to arguments
- Support multiple `--to` destinations
- Acceptance: `applemaps eta --from "SF" --to "Oakland" --to "SJC"`

### Phase 2: Directions & GUI Control

**S05: As a developer, I want full route directions so I can display turn-by-turn navigation**
- Implement `directions` command with from/to and transport mode
- Return Route array with steps, distance, duration
- Acceptance: `applemaps directions --from "Cupertino" --to "SF" --mode driving`

**S06: As a scripter, I want to batch geocode addresses so I can process large datasets**
- Add `--stdin` mode to `geocode` command
- Process one address per line sequentially
- Acceptance: `cat addresses.txt | applemaps geocode --stdin | jq '.results[].coordinate'`

**S07: As a user, I want to open Maps at a specific location so I can visualize programmatically**
- Implement `open` command with search/location/directions modes
- Construct and dispatch proper `maps://` URLs
- Acceptance: `applemaps open --location "37.78,-122.41" --zoom 14`

**S08: As a developer, I want to drop labeled pins so I can mark specific points**
- Implement `pin` command with coordinate + label
- Acceptance: `applemaps pin 37.78 -122.41 --label "Office"`

### Phase 3: Agent Integration

**S09: As an AI agent, I want structured tool schemas so I can discover capabilities**
- Implement MCP server mode (`applemaps mcp`)
- Expose all commands as typed MCP tools
- Acceptance: Claude Desktop can call applemaps tools via MCP

**S10: As an agent, I want field projection so I can minimize token usage**
- Implement `--fields` flag for all commands
- Support comma-separated field list
- Acceptance: `applemaps search "coffee" --fields name,coordinate | jq .`

**S11: As a scripter, I want shell completions so I can use the tool efficiently**
- Generate zsh/bash/fish completions
- Acceptance: Tab completion works for all commands and flags

**S12: As a developer, I want JSON schema export so I can validate outputs**
- Implement `applemaps --json-schema <command>` flag
- Export complete input/output schema for each command
- Acceptance: Agents can ingest schema for self-documentation

### Phase 4: Advanced Features

**S13: As a developer, I want search autocomplete so I can build type-ahead UIs**
- Implement `complete` command for search query completion
- Acceptance: `applemaps complete "star"` returns "Starbucks", "Star Market", etc.

**S14: As a user, I want to list POI categories so I know what filters are available**
- Implement `categories` command
- Return all available MKPointOfInterestCategory values
- Acceptance: `applemaps categories --format table`

**S15: As an enterprise user, I want to use the REST API backend for higher quotas**
- Implement `--backend server` flag
- Support Apple Maps Server API as alternative to local MapKit
- Acceptance: `applemaps search "coffee" --backend server` (requires API key in config)

---

## Technical Constraints

### Must Have
- Swift 6.0+ with strict concurrency enabled
- Swift Argument Parser 1.5+ for CLI framework
- macOS 13+ (Ventura) for async MapKit APIs
- No external dependencies beyond ArgumentParser
- Zero API keys required for local MapKit usage

### Must Not Have
- XCTest (use Swift Testing framework)
- Force unwraps or implicitly unwrapped optionals in production
- Interactive prompts or spinners by default
- Logging of sensitive location data to stdout
- UI scripting of Maps.app via Accessibility APIs

### Should Have
- Protocol-based service layer for testability
- Comprehensive Swift Testing test suite
- Graceful degradation on older macOS versions
- MCP server mode for AI agent integration

---

## Success Metrics

### Adoption
- 100+ GitHub stars in first 3 months
- 10+ Homebrew installs per week
- Featured in at least 2 dev tool roundups
- Integration in 3+ MCP server setups

### Quality
- 80%+ test coverage (unit + integration)
- Zero force crashes on malformed input
- < 5 bug reports per month after v1.0
- All PRD acceptance criteria passing

### Agent Friendliness
- LLMs successfully use tool without human intervention
- JSON schemas validated by external tools
- Zero ambiguous error messages
- Mentioned in AI coding agent documentation

---

## Non-Goals (Explicitly Out of Scope)

### Version 1.0
- ❌ Windows/Linux support (macOS-only via native MapKit)
- ❌ Graphical user interface
- ❌ Real-time location tracking or geofencing
- ❌ Map rendering or tile generation
- ❌ Offline map downloads
- ❌ Custom map overlays or annotations
- ❌ Navigation turn-by-turn voice guidance
- ❌ Traffic incident reporting
- ❌ Indoor mapping or venue details
- ❌ Multi-waypoint route optimization (only A→B routing)

### Future Consideration (Post-1.0)
- ⏸️ Apple Maps Server API as primary backend
- ⏸️ Cross-platform support via Server API
- ⏸️ Configuration file support (~/.applemapsrc)
- ⏸️ Persistent caching of geocoding results
- ⏸️ Maps Web Snapshot API for static map images
- ⏸️ Integration with Apple Shortcuts

---

## Dependencies & Risks

### External Dependencies
| Dependency | Version | Risk Level | Mitigation |
|---|---|---|---|
| Swift Argument Parser | 1.5+ | Low | Mature, Apple-maintained |
| MapKit Framework | System | Low | Stable, backward compatible |
| CoreLocation Framework | System | Low | Stable, backward compatible |

### Technical Risks
| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| MapKit rate limiting | Medium | Medium | Exponential backoff, sequential batching |
| macOS version changes break APIs | Low | High | Protocol-based abstraction, version checks |
| maps:// URL scheme changes | Low | Medium | Document current behavior, version detection |
| Swift 6 concurrency issues | Medium | Medium | Comprehensive testing, skill doc |

### Product Risks
| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Low adoption by agents | Medium | High | MCP integration, clear documentation |
| Users expect GUI features | Low | Low | Clear messaging: CLI-first tool |
| Confusion with Maps Server API | Medium | Low | Documentation, naming clarity |

---

## Open Questions

1. **Q:** Should we support custom user-agent strings for geocoding?  
   **A:** TBD — Investigate if Apple allows/respects custom UAs

2. **Q:** Should we cache geocoding results locally to reduce API calls?  
   **A:** No for v1.0 (privacy concerns) — revisit in 1.1 with opt-in

3. **Q:** Should we support reading API keys from environment variables for Server API?  
   **A:** Yes for Phase 4 (S15) — use `APPLE_MAPS_API_KEY` env var

4. **Q:** Should we support GPX export for routes?  
   **A:** Out of scope for v1.0 — potential v1.1 feature

5. **Q:** Should `--current-location` be supported in v1.0?  
   **A:** No — prefer explicit coordinates for agent-first design

---

## Appendix: maps:// URL Scheme Reference

*(See design document section "Apple Maps URL schemes — complete reference" for full parameter listing)*

**Supported base formats:**
- `maps://?{params}`
- `https://maps.apple.com/?{params}`

**Key parameters:**
- `q` — search query or pin label
- `ll` — center coordinates
- `sll` — search bias coordinates
- `daddr` / `saddr` — destination/source for directions
- `dirflg` — transport mode (d/w/r for drive/walk/transit)
- `z` — zoom level (2-21)
- `t` — map type (m/k/h for standard/satellite/hybrid)

---

**Document Status:** Draft  
**Next Review:** After Phase 1 completion  
**Approval Required:** Engineering Lead, Product Owner
