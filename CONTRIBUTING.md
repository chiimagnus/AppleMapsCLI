# Contributing to AppleMapsCLI

Bug reports and focused feature requests are welcome through the GitHub Issue forms. For code changes, read [AGENTS.md](AGENTS.md) before editing and use the pull request template.

Build and test on macOS with Swift 6:

```bash
swift build
swift test
```

Run the applicable real MapKit and Apple Maps checks when behavior changes; note any OS, architecture, permission or network cases that could not be tested. Do not include real private locations or credentials in issues or PRs. Releases and Homebrew distribution are described in [docs/release.md](docs/release.md).
