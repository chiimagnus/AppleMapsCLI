# AGENTS.md — applmaps (Codex-native instructions)

**Project:** `applmaps` — agent-first Apple Maps CLI for macOS (Swift 6, SwiftPM).  
**Goal:** Programmatic access to Apple Maps capabilities (search, geocode, reverse, ETA, directions) + GUI control via `maps://` URLs.  
**CLI Contract:** JSON-first, zero interactivity, semantic exit codes, pipe-friendly.

---

## Documentation Structure

This project has two complementary agent instruction files:

- **AGENTS.md (this file)** — Permanent project policy, architecture rules, technical constraints, and coding standards. Read this to understand the project's non-negotiable requirements and design decisions.

- **PROMPT.md** — Per-iteration instructions for autonomous development loops (Ralph/Codex). Read this when working in an autonomous agent context where you receive stories from prd.json and commit via TCR cycles.

**When to read which:**
- Manual development → Read AGENTS.md
- Autonomous agent loop → Read both AGENTS.md (project rules) and PROMPT.md (iteration protocol)
- Code review / onboarding → Read AGENTS.md
- Contributing → Read AGENTS.md first, then PROMPT.md if using autonomous workflows

---

## Autonomous Operation Mode

**This project is designed for fully autonomous development.**

When operating in autonomous mode (Codex/Ralph loops):

### You have permission to:
- ✅ **Proceed immediately** — Do not ask for permission or confirmation
- ✅ **Make all technical decisions** — Following AGENTS.md rules IS the permission
- ✅ **Add/modify dependencies** — As long as you document in commit message
- ✅ **Change Package.swift** — If needed for the story requirements
- ✅ **Create new files/modules** — Following the architecture boundaries (§5)
- ✅ **Refactor code** — If it improves quality and tests still pass
- ✅ **Update documentation** — Including this file (§13 Discovered Patterns)

### Your safety constraints:
- 🔒 **TCR discipline** — Every change must build and pass tests (§10)
- 🔒 **PROMPT.md phases** — Follow all 6 phases, especially Phase 5 (knowledge extraction)
- 🔒 **Exit codes** — Respect semantic exit codes (§3)
- 🔒 **Security/privacy** — Never log sensitive data (§11)
- 🔒 **Architecture boundaries** — Respect layering rules (§5)

### When to stop (failures only):
- ❌ Tests fail after 3 TCR attempts → Document in progress.txt and mark story blocked
- ❌ Build fails due to environment issue → Document error and stop
- ❌ Story requirements are ambiguous → Note in progress.txt, best-effort implementation

### Never stop to ask:
- ❌ "Should I add this dependency?" → YES, add it if needed
- ❌ "Should I refactor this?" → YES, if tests pass
- ❌ "Is this the right approach?" → Proceed with best judgment, TCR will validate
- ❌ "Can I create a new file?" → YES, follow architecture rules

**The process IS the permission structure.** Follow PROMPT.md phases religiously, and you have full autonomy to ship.

---

## 0) Swift 6 Skill Reference — READ FIRST

**CRITICAL:** Before writing ANY Swift code, read the Swift 6 skill document:

📖 **[`.agents/skills/swift6/SKILL.md`](https://raw.githubusercontent.com/rastreus/applspeech/refs/heads/main/.agents/skills/swift6/SKILL.md)**

This document covers:
- **Swift 6.2.3 strict concurrency** — Sendable protocol requirements, actor isolation
- **Swift Testing framework** — NOT XCTest (use `@Test`, `#expect`, `@Suite`)
- **Typed throws** (SE-0413) and error handling patterns
- **Swift Argument Parser** patterns for CLI tools
- **Common Swift 6 pitfalls** your training data may not reflect
- **Security best practices** for credential handling

### Key differences from your training data:
- All types crossing isolation boundaries MUST be `Sendable`
- Use Swift Testing (`import Testing`), NOT XCTest
- Prefer typed throws: `throws(SpecificError)` over untyped `throws`
- No force unwraps (`!`) in production code
- Actors for mutable state, Sendable value types for immutable data

### Quick checklist before coding:
- [ ] Read the Swift 6 skill if you haven't
- [ ] All structs/enums that cross async boundaries are `Sendable`
- [ ] Using `@Test` and `#expect`, not XCTest
- [ ] No force unwraps or implicitly unwrapped optionals
- [ ] Async/await for all network operations (MapKit, CoreLocation)

---

## 1) Build / test commands (run after changes)

### Standard workflow
- Build: `swift build 2>&1`
- Test: `swift test 2>&1`
- Single test: `swift test --filter <TestName> 2>&1`

### If sandbox restrictions exist (CI/Codex environments):
- Build: `swift build --disable-sandbox 2>&1`
- Test: `swift test --disable-sandbox 2>&1`

### Release sanity:
- `swift build -c release 2>&1`

---

## 2) Non-negotiables (agent guardrails)

### Always (strict requirements)
- **Read `.agents/skills/swift6/SKILL.md` before writing Swift code**
- Make small, single-purpose commits
- Keep commands **non-interactive** (no prompts/spinners/pagers by default)
- Default output **JSON** to stdout; human-friendly output only with `--format text|table`
- Respect Unix composability: stable schemas, deterministic output; compact JSON when piped
- Use async/await and actors; prefer structured concurrency over GCD
- All types crossing isolation boundaries MUST be `Sendable`
- Use Swift Testing (`@Test`, `#expect`), NOT XCTest
- Errors must be actionable and map to semantic exit codes (below)
- Add tests for new behaviors and regressions
- Document decisions in commit messages (not separately)

### Autonomous operation rules (when in doubt, proceed)
- **Adding dependencies?** → Add them. Document in Package.swift and commit message.
- **Changing Package.swift structure?** → Do it if story requires. Test that build succeeds.
- **Platform minimum unclear?** → Use macOS 13 per §12 unless story specifies otherwise.
- **Architecture decision needed?** → Follow §5 layering. If ambiguous, choose and document in §13.
- **Should I refactor?** → Yes, if tests pass and it improves code quality.
- **Need to create docs/?** → Create it. Use `docs/solutions/<topic>.md` pattern.

### Never (hard constraints)
- Force unwraps (`!`) or IUOs in production
- XCTest (use Swift Testing)
- Reading from stdin unless explicitly requested (`--stdin`) and documented
- Logging raw location/search data by default (only under `--verbose`)
- UI scripting of Maps.app via Accessibility/System Events (fragile)
- Logging passwords, API keys, or coordinates to stdout/logs
- Committing code that doesn't build (`swift build` must pass)
- Committing code that breaks tests (`swift test` must pass)

---

## 3) Semantic exit codes (STRICT)

- `0` — success
- `1` — user error (invalid args, parse failures, invalid coordinates, etc.)
- `2` — network/API error (MapKit/CoreLocation failures, throttling, transient errors)
- `3` — no results found (empty search/geocode results)

Do not invent additional codes without updating this doc and tests.

---

## 4) Output contract (agent-first)

### Global flags (applies to all commands)
- `--format json|text|table` (`json` default)
- `--pretty` (pretty JSON for TTY; compact JSON when piped unless `--pretty`)
- `--fields a,b,c` (projection of JSON fields; keep stable)
- `--quiet` (suppress non-essential stderr text)
- `--no-color` (and respect `NO_COLOR` env var)
- `--verbose` (diagnostics to stderr only; never pollute stdout JSON)

### Rules
- **Stdout:** ONLY the result payload (JSON/text/table). No logs.
- **Stderr:** diagnostics/errors (when appropriate)
- **JSON schemas must be stable:** additive changes OK, breaking changes require version bump and docs
- **Compact JSON when piped:** unless `--pretty` is explicitly set
- **Pretty JSON for TTY:** when outputting to terminal (isatty check)

---

## 5) Architecture & boundaries

### Layering (do not violate)
```
Utilities/ → Core/ → Output/ → Commands/ → @main
```

- `Core/` — business logic, service wrappers, models (no ArgumentParser import)
  - MapKit/CoreLocation wrappers
  - Data models (must be `Sendable`)
  - Service protocols for testability
- `Commands/` — CLI parsing + validation + calls into Core
  - ArgumentParser command definitions
  - Validation logic
  - Error translation to exit codes
- `Output/` — JSON/text/table rendering and field projection
  - OutputFormatter types
  - JSON encoding with snake_case keys
- `Utilities/` — shared helpers (parsing, formatting, errors)
  - Coordinate parsing
  - String formatters
  - Shared error types (must be `Sendable`)

**Dependency direction:** `Utilities → Core → Output → Commands → @main`

### Map backends
- **Data commands** use MapKit/CoreLocation (no API keys):
  - `MKLocalSearch` — place search
  - `MKDirections` — routes and ETAs
  - `CLGeocoder` — forward/reverse geocoding
- **GUI control** uses:
  - `NSWorkspace.open(URL)` with `maps://` / `https://maps.apple.com/` URLs

---

## 6) Core commands (required surface)

Command tree:
```
applmaps
├── search       MKLocalSearch (query, near/radius, categories, limit)
├── directions   MKDirections (routes + steps, optional alternatives, optional --open)
├── eta          MKDirections.calculateETA (supports multiple --to)
├── geocode      CLGeocoder forward (supports --stdin batch)
├── reverse      CLGeocoder reverse (coordinates → address)
├── open         Construct maps URL + dispatch (search/location/directions)
├── pin          Drop pin via maps URL (coordinates + optional label)
└── config       Manage tool configuration (if implemented; keep simple)
```

### Transport modes (when applicable)
- `driving` (default)
- `walking`
- `transit`
- `cycling` (requires macOS 14+, graceful degradation on older versions)

**Graceful degradation:** If unsupported on current macOS, return exit `2` with actionable message.

---

## 7) Models & schema guidelines

Use Codable models with explicit keys; prefer **snake_case** in JSON output.

### Core data models (all must be `Sendable`):
```swift
struct Coordinate: Sendable, Codable {
    let lat: Double
    let lon: Double
}

struct Address: Sendable, Codable {
    let street: String?
    let city: String?
    let state: String?
    let zip: String?
    let country: String?
    let isoCountry: String?
    let formatted: String
}

struct Place: Sendable, Codable {
    let name: String
    let coordinate: Coordinate
    let address: Address
    let phone: String?
    let url: String?
    let category: String?
    let timezone: String?
    let mapsUrl: String
}

struct Route: Sendable, Codable {
    let name: String
    let distanceM: Double
    let distanceText: String
    let durationS: Double
    let durationText: String
    let advisoryNotices: [String]
    let steps: [RouteStep]
}

struct RouteStep: Sendable, Codable {
    let instruction: String
    let distanceM: Double
    let distanceText: String
}

struct ETAResult: Sendable, Codable {
    let destination: String
    let coordinate: Coordinate
    let transportType: String
    let distanceM: Double
    let distanceText: String
    let travelTimeS: Double
    let travelTimeText: String
    let expectedArrival: String?  // ISO 8601
}
```

### JSON encoding rules:
- Use `snake_case` for all JSON keys (set `JSONEncoder.keyEncodingStrategy = .convertToSnakeCase`)
- ISO 8601 format for dates/times
- Meters for distances (provide text representation separately)
- Seconds for durations (provide text representation separately)
- Projection (`--fields`) must operate on the encoded JSON output, not internal types

---

## 8) Concurrency & reliability rules (Swift 6)

### Async/await patterns
- Prefer async APIs; wrap callback APIs safely
- All MapKit/CoreLocation operations are async (use `async/await`)
- No blocking with semaphores; use `@MainActor` if main-thread access required

### CLGeocoder guidance
- **One request at a time per instance**
- For `--stdin` batch mode: process sequentially, not in parallel
- Do not create hundreds of CLGeocoder instances

### MapKit throttling
- Handle `MKError.loadingThrottled` (or similar throttling errors)
- Implement bounded retries with exponential backoff
- Default: 3 retries with 1s, 2s, 4s delays
- Log throttling events to stderr when `--verbose`

### Actor isolation
```swift
// GOOD: Actor for mutable state
actor SearchCache {
    private var results: [String: [Place]] = [:]
    
    func get(_ query: String) -> [Place]? {
        results[query]
    }
    
    func set(_ query: String, places: [Place]) {
        results[query] = places
    }
}

// GOOD: Sendable value type for immutable data
struct SearchResult: Sendable {
    let query: String
    let places: [Place]
}
```

---

## 9) Testing requirements

### Use Swift Testing (NOT XCTest)
```swift
import Testing
@testable import ApplMaps

@Suite("Coordinate Parsing Tests")
struct CoordinateTests {
    
    @Test("Valid coordinate string")
    func validCoordinate() {
        let coord = Coordinate(string: "37.7749,-122.4194")
        #expect(coord?.lat == 37.7749)
        #expect(coord?.lon == -122.4194)
    }
    
    @Test("Invalid coordinate formats", arguments: [
        "invalid",
        "37.7749",  // missing longitude
        "abc,def",
        "37.7749,-200.0"  // invalid longitude
    ])
    func invalidCoordinate(input: String) {
        let coord = Coordinate(string: input)
        #expect(coord == nil)
    }
}
```

### Focus on deterministic tests
- **Parsing/validation:** coordinate parsing, flags, exit codes
- **URL construction:** `open`/`pin` commands (pure function tests)
- **Output formatting:** JSON stability, pretty/compact behavior, `--fields` projection
- **Error handling:** exit code mapping, error message formatting

### MapKit/CoreLocation tests
- Prefer **dependency inversion** with protocols + fakes for unit tests
- Use `protocol MapService` + `MockMapService` for testing commands
- Integration tests that hit real MapKit/CoreLocation:
  - Should be opt-in (separate test tag/suite)
  - Must be resilient to network failures
  - Keep CI deterministic by default (no live API calls)

### Example protocol-based testing:
```swift
// In Core/
protocol MapService: Sendable {
    func search(query: String, near: Coordinate?) async throws -> [Place]
}

// In Tests/
struct MockMapService: MapService {
    let stubbedResults: [Place]
    
    func search(query: String, near: Coordinate?) async throws -> [Place] {
        stubbedResults
    }
}

@Suite("Search Command Tests")
struct SearchCommandTests {
    @Test("Basic search")
    func basicSearch() async throws {
        let service = MockMapService(stubbedResults: [/* ... */])
        let command = SearchCommand(service: service)
        let output = try await command.run()
        #expect(output.results.count == 3)
    }
}
```

---

## 10) Workflow: small-step TCR with Jujutsu (jj)

Each loop: **one task → test → commit or revert**

### Standard workflow:
1. Update description early: `jj desc -m "feat(scope): brief description"`
2. Make change (one logical unit)
3. Verify: `swift build && swift test`
4. **If pass:** `jj new` (commit and start next)
5. **If fail:** `jj restore` (revert and try again)

### For autonomous agent iterations:
See **PROMPT.md** for the complete iteration protocol including:
- Phase 1: Orient (reading context files)
- Phase 2: Plan (breaking stories into TCR cycles)
- Phase 3: Implement (executing TCR loops)
- Phase 4: Verify (full test suite)
- Phase 5: Extract discoveries (knowledge compounding)
- Phase 6: Complete (update tracking files)

### Commit message format (Conventional Commits):
```
<type>(<scope>): <brief description>

<optional body>
```

**Types:** `feat`, `fix`, `test`, `refactor`, `docs`, `chore`

**Scopes:** `cli`, `commands`, `core`, `output`, `maps`, `geocode`, `directions`, `eta`, `url`, `config`, `tests`, `build`

### Examples:
```
feat(search): add category filtering support
fix(geocode): handle empty CLPlacemark results
test(directions): add route step formatting tests
refactor(core): extract MapService protocol
docs(readme): add installation instructions
```

---

## 11) Privacy & permissions

### Location data handling
- Treat **any location-derived data as sensitive**
- **Never log** raw coordinates, addresses, or search queries by default
- Only log under `--verbose` flag, and redact sensitive portions
- **Do not persist** search history or coordinates without explicit user opt-in

### Current location support
- `--current-location` (if implemented) will trigger macOS location permission dialog
- **Document this behavior clearly** in `--help` and README
- **Prefer explicit coordinates** for agent flows to avoid blocking on permission prompts
- Do not automatically request current location; require explicit flag

### Example safe logging:
```swift
// ❌ BAD
logger.debug("Searching for '\(query)' near \(coordinate)")

// ✅ GOOD
logger.debug("Performing search with \(results.count) results")

// ✅ GOOD (verbose only)
if verbose {
    logger.debug("Search query: '\(query)' (redacted coordinate)")
}
```

---

## 12) Package.swift configuration

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "applmaps",
    platforms: [.macOS(.v13)],  // Ventura for full async MapKit
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0")
    ],
    targets: [
        .executableTarget(
            name: "applmaps",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "applmapsTests",
            dependencies: ["applmaps"]
        )
    ],
    swiftLanguageModes: [.v6]
)
```

**Notes:**
- macOS 13 minimum for async MapKit support
- Cycling directions require macOS 14+ (degrade gracefully)
- Strict concurrency enabled by default in Swift 6
- No MapKit API key required for client usage

---

## 13) Discovered Patterns (knowledge compounding)

This section accumulates learnings from implementation iterations. When you discover gotchas, quirks, or useful patterns, document them here so future iterations don't repeat mistakes.

### Format:
```
### [Topic] — Brief description
**Discovered in:** Iteration N, Story S##
**Context:** What were you trying to do?
**Discovery:** What did you learn?
**Pattern:** Actionable code or guidance

[optional code example]
```

---

### ArgumentParser Subcommand Names — Set commandName explicitly
**Discovered in:** Iteration 1, Story S01
**Context:** `applmaps geocode "Apple Park"` was rejected even though `GeocodeCommand` was registered as a subcommand.
**Discovery:** ArgumentParser did not expose the intended CLI token from the type name in this setup.
**Pattern:** Always set `commandName` in each command's `CommandConfiguration`.

```swift
struct GeocodeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "geocode",
        abstract: "Convert an address into geographic coordinates."
    )
}
```

### Swift Entrypoint File Name — Avoid `@main` in `main.swift` for multi-file targets
**Discovered in:** Iteration 1, Story S01
**Context:** Build failed after adding more source files with `@main` still inside `Sources/.../main.swift`.
**Discovery:** Swift reported `'main' attribute cannot be used in a module that contains top-level code`.
**Pattern:** Use `@main` in a non-`main.swift` file (e.g., `ApplMaps.swift`) for executable targets with multiple source files.

### MapKit Rate Limiting — Handle throttling gracefully
**Context:** Placeholder for future discoveries during implementation
**Pattern:** When implemented, document retry strategies here

### CLGeocoder Batching — Sequential not parallel
**Context:** Placeholder for future discoveries during implementation  
**Pattern:** When implemented, document batching approach here

### maps:// URL Quirks — Coordinate snapping behavior
**Context:** Placeholder for future discoveries during implementation
**Pattern:** When implemented, document URL construction gotchas here

---

*(This section will grow as implementation proceeds. Each iteration should check: "Did I discover anything worth documenting here?")*

---

## 14) "Compound" step (make the system better each iteration)

After finishing a task/PR:
- If a **failure recurs**, add a guardrail to this doc (rule/test/checklist)
- Document **reusable patterns** in **§13 (Discovered Patterns)** above
- Track **module quality notes** in `docs/quality.md` (if used)
- Update Swift 6 skill reference if new patterns emerge

### Quality feedback loop:
- New Swift 6 concurrency error? → Add to skill doc's "Common Pitfalls"
- MapKit API quirk discovered? → Document in **§13** or `docs/solutions/mapkit-quirks.md`
- Flaky test? → Make deterministic or move to integration suite
- Verbose error message needed? → Add to error enum with context

---

## Quick Reference

### Build/test
```bash
swift build                           # Debug build
swift build -c release                # Release build
swift test                            # Run all tests
swift test --filter SearchTests       # Run specific suite
swift test --verbose                  # Verbose test output
```

### Run commands
```bash
.build/debug/applmaps search "coffee"
.build/debug/applmaps geocode "Apple Park"
.build/debug/applmaps eta --from "SF" --to "Oakland"
```

### Install (once implemented)
```bash
swift build -c release
cp .build/release/applmaps /usr/local/bin/
```

---

## 15) Autonomous Development Kickoff Prompt

**Use this prompt to start fully autonomous development:**

```
You are an autonomous software development agent working on the applmaps project.

Your mission: Implement the next incomplete story from prd.json following strict TCR discipline.

IMMEDIATE ACTIONS (in order):
1. Read progress.txt (last 30 lines) to understand current state
2. Read .agents/skills/swift6/SKILL.md for Swift 6 patterns
3. Read AGENTS.md §13 for discovered patterns from previous iterations
4. Identify next story: jq '.stories[] | select(.passes == false) | .id' prd.json | head -1
5. Read the story details from prd.json
6. Follow PROMPT.md phases 1-6 exactly

AUTONOMOUS OPERATION MODE:
- You have FULL PERMISSION to proceed without asking
- Make ALL technical decisions following AGENTS.md rules
- Add dependencies, modify Package.swift, create files as needed
- TCR discipline is your safety net (revert on test failure)
- Document discoveries in AGENTS.md §13 (Phase 5)

WORKFLOW:
- Break story into <50 line TCR cycles
- Each cycle: jj desc → code → swift build → swift test → jj new OR jj restore
- Every commit must build and pass tests
- Complete all 6 phases from PROMPT.md before marking story done

STOP CONDITIONS (only):
- Tests fail after 3 TCR attempts → document and stop
- Build errors unrelated to your code → document and stop
- Story requirements ambiguous → best-effort implementation, document in progress.txt

BEGIN NOW. Read progress.txt and start Phase 1 (Orient).
```

**This prompt assumes:**
- Repository is initialized with Package.swift, AGENTS.md, PROMPT.md, prd.json
- jj (Jujutsu) is configured and working
- Swift 6 toolchain is installed
- Initial commit exists as baseline

---

**Last updated:** 2026-02-15  
**Swift version:** 6.2.3  
**Platform:** macOS 13+ (Ventura)
