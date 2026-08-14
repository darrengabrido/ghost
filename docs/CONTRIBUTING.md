# Contributing to Ghost

## Branches

- `main` is always releasable.
- Branch names: `feature/short-description`, `fix/short-description`,
  `chore/short-description`.

## Commits

- Write commit messages that explain *why*, not just *what*.
- Keep commits scoped to one logical change.

## Before opening a PR

1. `xcodegen generate` if you touched `project.yml`.
2. `make lint` — fix or justify any SwiftLint warnings.
3. `make test` — all tests pass.
4. For UI changes, attach a screenshot or screen recording (Ghost is a
   visual, atmospheric app — reviewers need to see it).

## Code style

- Follow the patterns in [`docs/ARCHITECTURE.md`](ARCHITECTURE.md):
  `@Observable` ViewModels, protocol-first `Core/` services, constructor
  injection via `AppEnvironment`.
- New external integrations (voice providers, AI providers, storage) go
  behind a protocol in `Core/`, with a mock added to `GhostTests/Mocks`.
- No secrets in code or `Info.plist` — use `Ghost/Resources/Config/Secrets.xcconfig`
  (gitignored; see `Secrets.xcconfig.example`).

## Reporting bugs

Open a GitHub issue with reproduction steps, expected vs. actual behavior,
and device/iOS version. For voice-related bugs, note whether you're on
Simulator or a physical device — microphone/speech behavior differs
significantly between the two.
