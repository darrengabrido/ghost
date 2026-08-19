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

### CI has never actually run

Worth knowing before you rely on the first bullet: **no CI job in this
repository has ever been assigned a runner.** Every run since the initial
scaffold fails roughly three seconds after it is created, with
`runner_id: 0`, an empty runner name, and no logs at all (the logs endpoint
404s, because nothing ever started).

That signature is a runner *availability* problem at the account level —
macOS runners not enabled, or an Actions spending limit — not a fault in
this workflow or in the code being pushed. Nothing in the repository can
fix it; it has to be resolved in the account's Actions/billing settings.

The practical consequence: a green check has never been available here, and
right now **a real Mac is the only verification that exists**. Do not read a
failed CI run on this repo as a signal about your change until a job has
been seen to start.

One related trap, since it looks identical from the outside but is *not* the
same bug: an invalid `runs-on` label (for example `macos-26`, which this
account does not have) causes the run to be created with **zero jobs** rather
than with jobs that fail to start. If a run shows no jobs at all, check the
runner label first.
