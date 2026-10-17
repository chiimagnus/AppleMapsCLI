# Autonomous Development Mode — Quick Start

**This project is designed for fully autonomous AI development using Codex/Ralph.**

## One-Command Kickoff

Give your AI agent this single prompt to start autonomous development:

```
You are an autonomous software development agent working on applemaps.

Read these files in order:
1. AGENTS.md — Project rules and architecture
2. PROMPT.md — Your iteration protocol (6 phases)
3. progress.txt (tail -30) — What previous iterations did
4. .agents/skills/swift6/SKILL.md — Swift 6 patterns
5. AGENTS.md §13 — Discovered patterns from past iterations

Then execute PROMPT.md "Quick Start" section immediately.

You have FULL PERMISSION to:
- Add dependencies and modify Package.swift
- Create files and directories following AGENTS.md §5 architecture
- Refactor code if tests pass
- Make all technical decisions
- Proceed without asking questions

Your safety mechanism: TCR discipline
- Every change: jj desc → code → swift build → swift test
- If both pass: jj new (commit)
- If either fails: jj restore (revert)

Stop conditions (ONLY):
- Tests fail after 3 attempts → Document in progress.txt
- Build breaks due to environment → Document and stop
- Story is ambiguous → Best-effort implementation, document

BEGIN NOW. Start with PROMPT.md Quick Start section.
```

## What Happens Next

The agent will:

1. **Orient** (Phase 1)
   - Read progress.txt for context
   - Read Swift 6 skill document
   - Identify next incomplete story from prd.json
   - Review relevant code

2. **Plan** (Phase 2)
   - Break story into <50 line TCR cycles
   - Create implementation plan

3. **Implement** (Phase 3)
   - Execute TCR loops: describe → code → test → commit or revert
   - Make all technical decisions autonomously
   - No questions, just execution

4. **Verify** (Phase 4)
   - Run full test suite
   - Build release version
   - Manual smoke test if applicable

5. **Extract** (Phase 5)
   - Document discoveries in AGENTS.md §13
   - Add patterns to docs/solutions/ if needed

6. **Complete** (Phase 6)
   - Update prd.json (mark story passed)
   - Append to progress.txt
   - Commit tracking files

## Project Setup (One-Time)

Before first run:

```bash
# 1. Initialize repository
git init
jj init --git-repo=.

# 2. Create initial structure
mkdir -p Sources/AppleMapsCLI Tests/AppleMapsCLITests .agents/skills/swift6 docs/solutions

# 3. Add project files
# - Copy AGENTS.md, PROMPT.md, prd.json to root
# - Copy Swift 6 skill to .agents/skills/swift6/SKILL.md
# - Create initial Package.swift (see AGENTS.md §12)

# 4. Create progress.txt
echo "## Iteration 0 — Initial Setup" > progress.txt
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> progress.txt
echo "- Project initialized" >> progress.txt
echo "- AGENTS.md, PROMPT.md, prd.json in place" >> progress.txt

# 5. Initial commit
jj new -m "chore(init): project scaffolding"
swift build  # Should succeed (empty project is fine)
jj new
```

## Monitoring Progress

Watch the agent work:

```bash
# Monitor commits
jj log --limit 20

# Check current story
jq '.stories[] | select(.passes == false) | .id' prd.json | head -1

# Read progress
tail -50 progress.txt

# See discovered patterns
cat AGENTS.md | grep -A100 "§13"
```

## Agent Stopped? Restart

If agent stops due to repeated test failures:

```bash
# 1. Check progress.txt for the issue
tail -20 progress.txt

# 2. Fix the issue manually if needed (environment, missing dependency, etc.)

# 3. Restart with the same kickoff prompt
# Agent will pick up where it left off (next incomplete story)
```

## Key Files

| File | Purpose |
|---|---|
| `AGENTS.md` | Permanent project rules, architecture, constraints |
| `PROMPT.md` | Per-iteration instructions for autonomous loops |
| `prd.json` | Story backlog (generated from prd.md) |
| `progress.txt` | Iteration history (human + agent readable) |
| `.agents/skills/swift6/SKILL.md` | Swift 6 reference guide |
| `docs/solutions/` | Accumulated solutions and patterns |

## Safety Mechanisms

**The agent cannot break the project because:**

1. **TCR discipline** — Bad code never commits (test failures = revert)
2. **AGENTS.md rules** — Hard constraints (no force unwraps, Sendable types, etc.)
3. **PROMPT.md phases** — Structured process with verification
4. **Git/jj safety** — Every commit is a restore point
5. **Semantic exit codes** — Errors are detected programmatically

**Trust the process. The agent has full autonomy because the process ensures safety.**

---

## Example Session

```
Agent receives kickoff prompt
→ Reads AGENTS.md (learns rules)
→ Reads PROMPT.md (learns process)
→ Reads progress.txt (learns history)
→ Identifies Story S02: "Implement geocode command"
→ Creates TCR plan (6 small cycles)
→ Cycle 1: Add Coordinate model → swift build ✓ → swift test ✓ → jj new
→ Cycle 2: Add Address model → swift build ✓ → swift test ✓ → jj new
→ Cycle 3: Add GeocodeService → swift build ✓ → swift test ✗ → jj restore
→ Cycle 3 (retry): Smaller change → swift build ✓ → swift test ✓ → jj new
→ Cycles 4-6: Complete command, tests, wiring
→ Phase 4: Verify (swift build -c release ✓, swift test --verbose ✓)
→ Phase 5: Document pattern in AGENTS.md §13
→ Phase 6: Update prd.json, progress.txt, commit
→ Agent ready for next story (or stops if all done)
```

**Total human intervention: 0**

---

**Ready to ship at inference speed.** 🚀
