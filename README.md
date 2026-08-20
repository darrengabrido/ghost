# Ghost 👻

**Ghost** is a voice-first AI companion for iOS. No chat bubbles to type
into, no forms to fill out — you talk, Ghost listens, and it answers back
in a voice of its own. The whole app is built around a dark, mysterious,
atmospheric aesthetic: it should feel less like "an app with a
chatbot" and more like something present in the room with you.

> This repository is a from-scratch, production-ready starting point —
> architecture, folder structure, and design system are in place, with a
> live Anthropic + on-device Speech integration. Every provider is behind
> a protocol, so swapping or adding one is one adapter file, not a
> rewrite.

## Features (planned)

- 🎙️ **Voice-first conversation** — press-and-hold or wake-word activated
  listening, live transcription, streamed spoken responses.
- 🌘 **Atmospheric UI** — a single breathing, pulsing "presence" (the
  orb) that reacts to Ghost listening, thinking, and speaking, over a
  dark, minimal canvas.
- 🗂️ **Conversation history** — past conversations saved locally and
  searchable.
- ⚙️ **Configurable voice & AI providers** — pick Anthropic, OpenAI, xAI
  Grok, or Google Gemini as the LLM right from Settings, each with its own
  saved key; speech-to-text and text-to-speech are equally swappable
  without touching UI code.
- 🔒 **Privacy-conscious by default** — no analytics wired in, API keys
  never committed, microphone access explained plainly to the user.

## Tech stack

| Layer | Choice |
|---|---|
| UI | SwiftUI |
| State management | `@Observable` macro (no Combine, no third-party state library) |
| Persistence | SwiftData |
| Concurrency | Swift Concurrency (`async`/`await`, `AsyncStream`) |
| Project generation | [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`project.yml` → `Ghost.xcodeproj`, never committed) |
| Minimum iOS | 26.0 |
| Swift | 6.0 |

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full rationale.

## Requirements

- Xcode 26+ (Ghost targets iOS 26 for Liquid Glass)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- [SwiftLint](https://github.com/realm/SwiftLint) (optional but recommended): `brew install swiftlint`

## Getting started

```bash
git clone <your-fork-or-repo-url>.git
cd ghost

# One-shot setup: checks Xcode/XcodeGen/SwiftLint, creates Secrets.xcconfig
# from the template, and generates Ghost.xcodeproj (macOS only — see
# docs/DEV_ENVIRONMENT.md for Claude Code on the web / other Linux sessions)
scripts/setup.sh --open
# then edit Ghost/Resources/Config/Secrets.xcconfig with your real API keys
```

Build and run on a **physical device** for anything voice-related —
the iOS Simulator's microphone and speech recognition behavior is
unreliable and doesn't reflect real usage.

### Useful commands

```bash
make generate   # regenerate Ghost.xcodeproj from project.yml
make build      # build for Simulator from the command line
make test       # run unit + UI tests
make lint       # run SwiftLint
```

## Project structure

```
Ghost/
  App/            # @main entry point + composition root (AppEnvironment)
  Resources/      # Assets, Info.plist, entitlements, xcconfig
  DesignSystem/   # Dark/atmospheric theme, reusable components, animations
  Navigation/     # App-level routing
  Features/       # Screen-level Views + @Observable ViewModels
    Onboarding/
    Conversation/
    History/
    Settings/
  Core/           # Protocol-first services — no feature depends on another feature
    Voice/        # Speech recognition, speech synthesis, audio session, VAD
    AI/           # LLM conversation service (streaming), prompt building
    Persistence/  # SwiftData-backed conversation store
    Networking/   # Thin API client
    Utilities/    # Logging, Keychain, extensions
GhostTests/       # Unit tests + mocks for Core protocols
GhostUITests/     # UI tests
docs/             # Architecture and contribution docs
```

## Architecture at a glance

- **SwiftUI + `@Observable`** ViewModels per feature — no Combine
  boilerplate, async work modeled with `async`/`await` and `AsyncStream`.
- **Protocol-first `Core/` services** (`VoiceEngine`, `AIConversationService`,
  `ConversationStore`, ...) so voice/AI providers can be swapped by adding
  one adapter, not rewriting features.
- **`AppEnvironment`** as a lightweight, constructor-injected composition
  root — no DI framework.

Full details: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

See [`docs/DEV_ENVIRONMENT.md`](docs/DEV_ENVIRONMENT.md) for the full setup
story, including what a non-macOS session (e.g. Claude Code on the web) can
and can't do.

## Configuration & secrets

API keys and environment-specific values live in
`Ghost/Resources/Config/Secrets.xcconfig`, which is **gitignored**. Only
`Secrets.xcconfig.example` (a template with placeholder keys) is committed.
Never put real keys in `Info.plist`, source files, or `project.yml`.

## Contributing

See [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md) for branch naming,
commit conventions, and the pre-PR checklist.

## License

[MIT](LICENSE)
