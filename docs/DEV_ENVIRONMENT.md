# Development environment

Ghost is an iOS app (SwiftUI, SwiftData, XCTest) generated from `project.yml`
via XcodeGen. Building and testing it means running `xcodebuild` against the
iOS SDK and Simulator, which only exist on macOS + Xcode — there is no
Linux or cross-platform build path, and none is planned (this isn't a Swift
Package with a `Package.swift`).

## On a Mac

```bash
git clone <repo-url>.git && cd ghost
scripts/setup.sh
```

`scripts/setup.sh` checks for Xcode/XcodeGen/SwiftLint (installing the
latter two via Homebrew if missing), creates
`Ghost/Resources/Config/Secrets.xcconfig` from the template, and runs
`xcodegen generate`. From there:

```bash
make build   # build for Simulator
make test    # run unit + UI tests
make lint    # run SwiftLint
```

Build and run on a **physical device** for anything voice-related — the
Simulator's microphone and speech recognition behavior is unreliable. Open
`Ghost.xcodeproj` in Xcode and run on a connected, trusted device, or use
`xcodebuild ... -destination "id=<device-udid>"` from the command line.

## In Claude Code on the web / other Linux sessions

These sessions run in a Linux container with no Xcode, no iOS SDK, and no
Swift toolchain — `xcodegen generate`, `xcodebuild`, and every `make` target
above simply cannot run here, regardless of network access. A
`.claude/hooks/session-start.sh` SessionStart hook runs automatically at the
start of each such session and does the subset of setup that *is* possible
on Linux:

- creates `Ghost/Resources/Config/Secrets.xcconfig` from the template if it's
  missing, so file references resolve consistently;
- validates `project.yml` as YAML, to catch a syntax error before it reaches
  CI as a confusing `xcodegen generate` failure.

Real verification for changes made in one of these sessions happens via:

- **CI** — [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) runs
  `xcodegen generate`, a full build, the test suite, and `swiftlint --strict`
  on `macos-15` GitHub Actions runners for every push/PR to `main`.
- **A real Mac** — pull the branch and run `scripts/setup.sh` + `make test`.

Treat code changes made in a Linux session as unverified until one of those
two has actually run.
