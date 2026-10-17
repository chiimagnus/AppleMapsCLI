# Release & Homebrew

AppleMapsCLI publishes free, universal macOS binaries (ARM64 + x86_64) through [GitHub Releases](https://github.com/chiimagnus/AppleMapsCLI/releases). It uses native MapKit and requires no paid API, token, telemetry service or map provider subscription.

## Install

```bash
brew install chiimagnus/tap/applemapscli
applemaps --help
```

For source builds, see [README](../README.md). The binary targets macOS 13+; the multi-stop `open --via` link requires macOS 15.4+.

## Release contract

- `.github/workflows/ci.yml` validates macOS ARM64 and Intel using Xcode 26+ (including selecting the installed Xcode 26 SDK on macOS 15 Intel, whose default Xcode 16 SDK lacks MapKit cycling APIs). No release is created for an unverified commit.
- After the `main` push CI succeeds, maintainers push a stable tag `vMAJOR.MINOR.PATCH` **pointing to an ancestor of main**. `.github/workflows/release.yml` verifies the exact commit's CI and checks for an existing Release.
- The release builds and tests a single universal `applemaps-macos-universal.tar.gz`, checks both architectures and macOS 13 deployment, and executes the extracted archive on an Intel runner before publishing. GitHub signs an artifact attestation.
- The separate [homebrew-tap](https://github.com/chiimagnus/homebrew-tap) Formula pins that published archive by SHA-256. Its updater checks the latest stable Release every 6 hours and can also be dispatched manually.
- Tag workflow failure, GitHub API failure, archive checksum mismatch or Intel verification failure must stop publishing. Do not publish arbitrary local binaries or reuse a checksum from a different Release.

To start a release after successful main CI:

```bash
git tag v0.1.0
git push origin v0.1.0
```

For later releases choose a new version, not the example above. Failed releases are recovered by inspecting the workflow, fixing the cause and cutting a new tag where necessary; avoid force-moving published tags.
