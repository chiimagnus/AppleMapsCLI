# Release & Homebrew

AppleMapsCLI publishes free, Apple Silicon (arm64) binaries through [GitHub Releases](https://github.com/chiimagnus/AppleMapsCLI/releases). It uses native MapKit and requires no paid API, token, telemetry service or map provider subscription.

## Install

```bash
brew install chiimagnus/tap/applemapscli
applemaps --help
```

For source builds, see [README](../README.md). The binary targets macOS 15.6+ on Apple Silicon.

## Release contract

- `.github/workflows/ci.yml` validates Apple Silicon on macOS 15 and 26 using Xcode 26+ (macOS 15 runners explicitly select Xcode 26). No release is created for an unverified commit.
- After the `main` push CI succeeds, maintainers push a stable tag `vMAJOR.MINOR.PATCH` **pointing to an ancestor of main**. `.github/workflows/release.yml` verifies the exact commit's CI and checks for an existing Release.
- The release builds and tests a single arm64 `applemaps-macos-arm64.tar.gz`, checks macOS 15.6 deployment, and executes the extracted archive on a macOS 15 Apple Silicon runner before publishing. GitHub signs an artifact attestation.
- The separate [homebrew-tap](https://github.com/chiimagnus/homebrew-tap) Formula pins that published archive by SHA-256. Its updater checks the latest stable Release every 6 hours and can also be dispatched manually.
- Tag workflow failure, GitHub API failure, archive checksum mismatch or macOS 15 runtime verification failure must stop publishing. Do not publish arbitrary local binaries or reuse a checksum from a different Release.

To start a release after successful main CI:

```bash
git tag v0.1.0
git push origin v0.1.0
```

For later releases choose a new version, not the example above. Failed releases are recovered by inspecting the workflow, fixing the cause and cutting a new tag where necessary; avoid force-moving published tags.
