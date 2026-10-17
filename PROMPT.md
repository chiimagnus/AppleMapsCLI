# PROMPT.md — Per-Iteration Agent Instructions

> This file is read by the agent at the start of each Ralph loop iteration.
> It complements AGENTS.md (project policy) with iteration-specific behavior.

**🤖 AUTONOMOUS MODE ENABLED:**
- You have FULL PERMISSION to proceed without asking
- Make technical decisions following AGENTS.md rules
- Add dependencies, modify files, refactor as needed
- TCR discipline (test-commit-revert) is your safety net
- Only stop if tests fail repeatedly or build breaks
- **DO NOT ASK QUESTIONS — EXECUTE**

---

## Quick Start (Autonomous Agent Entry Point)

**When you receive this file, immediately execute these steps:**

```bash
# 1. Orient — Read context (DO NOT ASK, JUST READ)
cat progress.txt | tail -30
cat .agents/skills/swift6/SKILL.md | head -100
cat AGENTS.md | grep -A50 "§13"

# 2. Get assignment (DO NOT ASK, JUST FETCH)
export STORY_ID=$(jq -r '.stories[] | select(.passes == false) | .id' prd.json | head -1)
echo "Assigned: $STORY_ID"
jq ".stories[] | select(.id == \"$STORY_ID\")" prd.json

# 3. Verify baseline (DO NOT ASK, JUST VERIFY)
swift build
swift test

# 4. Start first commit (DO NOT ASK, JUST START)
jj new -m "feat(scope): start $STORY_ID"
```

**Then immediately proceed to Phase 1 (Orient) below.**

**NO ASKING. NO WAITING. EXECUTE.**

---

## Context

You are running inside an autonomous loop. Each iteration:

1. You receive ONE story from prd.json to implement.
2. You have a fresh context window — no memory of previous iterations.
3. Your only memory is: jj history, progress.txt, and prd.json status.

**You are operating in FULL AUTONOMOUS MODE:**
- Proceed immediately without asking permission
- Make all technical decisions following AGENTS.md rules
- TCR (test-commit-revert) discipline is your safety mechanism
- Add dependencies, create files, refactor code as needed
- Only stop if tests fail repeatedly or build breaks

**Read progress.txt first.** It tells you what previous iterations accomplished
and any decisions or gotchas they discovered. This saves you from re-exploring
the entire codebase.

**Read `.agents/skills/swift6/SKILL.md` before writing Swift code.** This
documents Swift 6 concurrency patterns, Swift Testing syntax, and common
pitfalls that your training data may not reflect.

---

## Iteration Protocol

### Phase 1: Orient (do this before writing any code)

1. **Read context files**:
   ```bash
   cat progress.txt | tail -30        # Recent iteration summaries
   cat .agents/skills/swift6/SKILL.md # Swift 6 patterns
   cat AGENTS.md | head -100           # Project rules reminder
   ```

2. **Understand your assignment**:
   ```bash
   # Read your assigned story
   jq '.stories[] | select(.id == "S##")' prd.json
   ```
   
3. **Check repository state**:
   ```bash
   jj log --limit 10                  # Recent commits
   jj st                              # Working copy status
   ls Sources/AppleMapsCLI/               # Current structure
   tree Sources/ Tests/ -L 2          # Overview of modules
   ```

4. **Review relevant code**:
   - Check Package.swift for dependencies
   - Examine existing modules you'll interact with
   - Review existing tests to understand patterns
   - **Read AGENTS.md §13 (Discovered Patterns)** — learn from prior iterations
   - Check `docs/solutions/` for documented solutions

5. **Verify you can build and test**:
   ```bash
   swift build                        # Should succeed before you start
   swift test                         # Baseline: all tests pass
   ```

### Phase 2: Plan

Write your TCR cycle plan before touching any code. Break the story into
atomic changes, each of which can be tested independently.

**Example plan for S02-geocode-command**:
```
TCR Plan:
  1. Add Coordinate model with string parsing — test parsing
  2. Add Address model with CLPlacemark init — test mapping
  3. Add GeocodeService protocol + MapKitGeocodeService — test service layer
  4. Add GeocodeCommand with ArgumentParser — test CLI parsing
  5. Wire service into command with JSON output — test end-to-end
  6. Add --stdin batch mode — test batch processing
  7. Add error handling with exit codes — test error paths
```

Each step should:
- Be < 50 lines of code
- Have a clear test or verification
- Leave the codebase in a working state

### Phase 3: Implement (TCR Loop)

For each step in your plan:

```bash
# 1. Describe what you're doing
jj desc -m "feat(geocode): add Coordinate model with parsing"

# 2. Make the change (edit one or two files)

# 3. Verify
swift build
swift test

# 4. Decide:
# ✅ Both pass → commit and move to next step
jj new

# ❌ Either fails → revert and try smaller change
jj restore
```

**TCR Discipline**:
- If `swift build` fails: your change broke compilation → revert
- If `swift test` fails: you broke existing behavior → revert
- Don't "fix forward" — revert and make a smaller change
- Never commit code that doesn't build or pass tests

**MapKit-specific TCR notes**:
- MapKit/CoreLocation tests may need network → stub with protocols
- Integration tests are opt-in, keep CI deterministic
- Test URL construction for `open`/`pin` commands (no network needed)

### Phase 4: Verify Story Completion

Before marking the story done, run the full verification suite:

```bash
# Type checking
swift build

# Release build (optimizations may catch issues)
swift build -c release

# All tests
swift test --verbose

# Manual smoke test if command is user-facing
.build/debug/applemaps geocode "Apple Park" --format json
.build/debug/applemaps search "coffee" --format text
```

**ALL must pass.** If any fails, fix it before completing the story.

### Phase 5: Extract & Document Discoveries (COMPOUNDING STEP)

**This step is critical. Do not skip it.**

Before marking the story complete, explicitly ask yourself:

1. **Did I encounter any MapKit/CoreLocation quirks?** (API behavior, rate limits, edge cases)
2. **Did I learn anything about the `maps://` URL scheme?**
3. **Did I discover any patterns that future iterations should know?**
4. **Were there any Swift 6 concurrency issues I needed to solve?**
5. **Did I find any helpful ArgumentParser patterns?**

If you discovered ANYTHING worth documenting:

1. **Append to AGENTS.md §13 (Discovered Patterns)**:
   - Add a clear, actionable entry
   - Include code examples if helpful
   
2. **OR create/update `docs/solutions/<topic>.md`** for larger topics:
   - `docs/solutions/mapkit-quirks.md` — MapKit API gotchas
   - `docs/solutions/url-scheme-behavior.md` — maps:// URL findings
   - `docs/solutions/concurrency-patterns.md` — Swift 6 actor patterns
   
3. **Commit documentation updates separately:**
   ```bash
   jj desc -m "docs: add MapKit rate limiting pattern"
   jj new
   ```

This is how the project compounds knowledge over iterations. Future agents
will read these docs and avoid repeating your mistakes.

### Phase 6: Complete

1. **Update prd.json**: Set your story's `"passes"` to `true`

2. **Append to progress.txt**:
   ```
   ## Iteration N — S##-story-id — Story Title
   Date: YYYY-MM-DDTHH:MM:SSZ
   - Brief summary of what was implemented
   - Key technical decisions (e.g., "used CLGeocoder sequential batching")
   - Files added/modified
   - MapKit/CLI gotchas discovered
   - Test coverage notes (e.g., "unit tests + integration opt-in")
   - Patterns added to AGENTS.md §13 or docs/solutions/ (if any)
   ```

3. **Commit tracking files**:
   ```bash
   jj desc -m "chore(ralph): complete story S##-story-id"
   jj new
   ```

---

## Rules

### Story Scope
- **One story per iteration.** Never work on unassigned stories.
- **Finish completely.** All acceptance criteria must be met.
- **No partial work.** Either complete the story or don't commit tracking files.

### Code Quality
- **TCR is mandatory.** No large uncommitted changes.
- **No stubs.** No TODO comments, no placeholder functions.
- **No skipping tests.** New code = new tests.
- **Privacy first.** Follow AGENTS.md §11 privacy/security guidelines.
- **Swift 6 patterns.** All models Sendable, strict concurrency, actors for state.
- **JSON-first output.** Default to JSON, respect `--format` flag.

### Testing
- **Use Swift Testing.** `@Test` macros, not XCTest.
- **Test error paths.** Map to semantic exit codes (0/1/2/3).
- **Test CLI parsing.** Verify ArgumentParser flags work correctly.
- **Test output formatting.** JSON stability, `--fields` projection, `--pretty`.
- **Stub MapKit/CoreLocation.** Use protocols + mocks for deterministic tests.

### Documentation
- **Document public APIs.** Use `///` comments with parameters and examples.
- **Update README.** If you add user-facing commands, document them.
- **Keep progress.txt concise.** Future iterations read it for context.
- **Extract solutions.** MapKit quirks go in `docs/solutions/`.

---

## Common Workflows

### Starting Work
```bash
# 1. Read context
cat progress.txt | tail -30

# 2. Read discovered patterns
cat AGENTS.md | grep -A100 "§13"

# 3. Get your assignment
export STORY_ID=$(jq -r '.stories[] | select(.passes == false) | .id' prd.json | head -1)
jq ".stories[] | select(.id == \"$STORY_ID\")" prd.json

# 4. Create first commit
jj new -m "feat(scope): start $STORY_ID"
```

### During Implementation
```bash
# Make small change
jj desc -m "feat(geocode): add Coordinate parsing"

# Verify
swift build && swift test

# Commit or revert
swift test && jj new || jj restore
```

### Completing Story
```bash
# Final verification
swift build -c release && swift test --verbose

# Manual test if command is user-facing
.build/debug/applemaps <command> <args>

# === CRITICAL: Check for discoveries ===
# Did you discover anything? Update AGENTS.md §13 or docs/solutions/

# Update tracking
jq '.stories[] |= if .id == "S##" then .passes = true else . end' prd.json > tmp.json && mv tmp.json prd.json

# Append to progress.txt (use your editor)

# Commit
jj desc -m "chore(ralph): complete story S##-story-id"
jj new
```

---

## Swift 6 Quick Reference (applemaps-specific)

### Testing Patterns
```swift
import Testing
@testable import AppleMapsCLI

@Suite("Coordinate Parsing Tests")
struct CoordinateTests {
  
  @Test("Valid coordinate formats", arguments: [
    ("37.7749,-122.4194", 37.7749, -122.4194),
    ("0.0,0.0", 0.0, 0.0),
    ("-90.0,-180.0", -90.0, -180.0)
  ])
  func validParsing(input: String, lat: Double, lon: Double) {
    let coord = Coordinate(string: input)
    #expect(coord?.lat == lat)
    #expect(coord?.lon == lon)
  }
  
  @Test("Invalid formats return nil", arguments: [
    "invalid",
    "37.7749",  // missing component
    "200.0,0.0" // out of range
  ])
  func invalidParsing(input: String) {
    #expect(Coordinate(string: input) == nil)
  }
}
```

### Sendable Models
```swift
// All models MUST be Sendable for async MapKit operations
struct Coordinate: Sendable, Codable {
  let lat: Double
  let lon: Double
  
  init?(string: String) {
    let components = string.split(separator: ",")
    guard components.count == 2,
          let lat = Double(components[0]),
          let lon = Double(components[1]),
          (-90...90).contains(lat),
          (-180...180).contains(lon) else {
      return nil
    }
    self.lat = lat
    self.lon = lon
  }
}

enum MapError: Error, Sendable {
  case invalidCoordinate(String)
  case searchFailed(String)
  case noResults
}
```

### Async MapKit Wrapper
```swift
protocol MapService: Sendable {
  func search(query: String, near: Coordinate?) async throws -> [Place]
}

struct MapKitService: MapService {
  func search(query: String, near: Coordinate?) async throws -> [Place] {
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = query
    
    if let near = near {
      let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
      request.region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: near.lat, longitude: near.lon),
        span: span
      )
    }
    
    let search = MKLocalSearch(request: request)
    let response = try await search.start()
    return response.mapItems.map { Place(from: $0) }
  }
}
```

### JSON Output Pattern
```swift
struct SearchOutput: Sendable, Codable {
  let query: String
  let count: Int
  let results: [Place]
  
  enum CodingKeys: String, CodingKey {
    case query
    case count
    case results
  }
}

// In command:
func run() async throws {
  let results = try await service.search(query: query, near: near)
  let output = SearchOutput(query: query, count: results.count, results: results)
  
  let encoder = JSONEncoder()
  encoder.keyEncodingStrategy = .convertToSnakeCase
  encoder.outputFormatting = isatty(STDOUT_FILENO) == 1 ? .prettyPrinted : []
  
  let data = try encoder.encode(output)
  print(String(data: data, encoding: .utf8)!)
}
```

---

## Debugging TCR Failures

### Build Fails
```bash
swift build 2>&1 | less  # Read full error output
```
Common causes:
- Missing import (MapKit, CoreLocation, ArgumentParser)
- Sendable conformance violation (all async types must be Sendable)
- Type mismatch (Swift 6 is strict)
- File not added to Package.swift targets

### Tests Fail
```bash
swift test --verbose     # See which test failed and why
```
Common causes:
- Async test not using `async throws`
- Mock MapService not returning expected data
- JSON encoding doesn't match schema
- Exit code assertion wrong (check AGENTS.md §3)

### Command Works But Output Wrong
```bash
.build/debug/applemaps <cmd> --verbose 2>&1 | less
```
Check:
- JSON schema matches spec
- `--format text` vs `json` behavior
- `--pretty` flag vs piped output
- Exit codes (0/1/2/3) match error type

---

## MapKit/CoreLocation Gotchas

### Rate Limiting
- CLGeocoder: process sequentially, NOT in parallel
- MKLocalSearch: may return `MKError.loadingThrottled`
- Implement exponential backoff: 1s, 2s, 4s delays

### Error Handling
```swift
do {
  let response = try await search.start()
} catch let error as MKError {
  switch error.code {
  case .loadingThrottled:
    throw MapError.rateLimited
  case .placemarkNotFound:
    throw MapError.noResults
  default:
    throw MapError.searchFailed(error.localizedDescription)
  }
}
```

### maps:// URL Construction
```swift
// Coordinates must be percent-encoded in query string
let query = "q=\(lat),\(lon)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
let url = URL(string: "maps://?\(query)")!
NSWorkspace.shared.open(url)
```

---

## Communication Style

Be direct. No preamble. No questions. **JUST EXECUTE.**

**Autonomous operation examples:**

✅ **CORRECT (autonomous):**
```
Reading progress.txt... Story S02 assigned.

TCR Plan:
1. Add Coordinate model with parsing — test
2. Add Address model — test  
3. Wire to GeocodeCommand — test

Starting Cycle 1...
[proceeds immediately with implementation]
```

❌ **WRONG (asking permission):**
```
I see we need to implement geocoding. Should I:
1. Create a new Coordinate struct?
2. Add it to the Core/ directory?
Let me know which approach you prefer.
```

❌ **WRONG (verbose preamble):**
```
Great! I'll start by reading the progress file to understand what's been done so far, 
then I'll examine the story requirements and create a comprehensive plan...
```

**Key principles:**
- State what you're doing, then do it
- Never ask "Should I...?" — Decide and proceed
- Never ask "Where should I put this?" — Follow AGENTS.md §5 architecture
- Never ask "Is this the right approach?" — Implement, TCR will validate
- If uncertain, pick the most reasonable option and document in commit message

**IMPORTANT REMINDER**: After completing the story, don't forget Phase 5 — extract and document any discoveries to AGENTS.md §13!

Just: **Orient → Plan → Execute → Verify → Extract Discoveries → Complete**.
