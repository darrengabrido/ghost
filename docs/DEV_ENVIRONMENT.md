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

### CI was broken for its entire history — read this before trusting a run

Between commit `33afcdd` and this one, **no CI run in this repository ever
produced a single job.** The cause was in the workflow file itself:
`33afcdd` (titled, with some irony, "Unblock CI") added a `python3 - <<'PY'`
heredoc inside a `run: |` block whose body sat at column 0. A YAML block
scalar ends at the first line that isn't indented past its parent, so the
heredoc terminated the block and made the whole file unparseable. GitHub
rejected it before creating any job, which surfaces as a run that fails
instantly with no jobs, no logs, and no error you can click on.

That is fixed here by moving the script into an `env:` block scalar, which
is indented with the document and dedented by YAML before Python sees it.
**Validate this file locally before pushing a change to it** — the failure
mode is silent and costs a full round trip:

```sh
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"
```

Two failure fingerprints are worth telling apart, because they look
identical from the PR page and have nothing to do with each other:

| Symptom | Cause |
|---|---|
| Run created, **zero jobs** | Workflow file invalid, or an unknown `runs-on` label |
| Jobs created, `runner_id: 0`, ~3s, logs 404 | No runner was ever assigned — an account/runner-availability problem |

The second was seen once, on the very first run, before the file broke. It
has not been observable since, because nothing has got far enough to try.
If it reappears now that the file parses, that one is an account-level
Actions/billing setting and nothing in this repository can fix it.

Until a job has actually been seen to start, treat **a real Mac as the only
verification that exists.**
