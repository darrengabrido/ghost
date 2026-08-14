# Architecture

Ghost is a SwiftUI app built around the **`@Observable` macro** rather than a
third-party state management framework. The goal is to keep the dependency
surface small while still getting clean separation of concerns and testable
business logic — important for a voice-first app where a lot of state
(listening / thinking / speaking, live transcript, streaming AI tokens) is
asynchronous and time-sensitive.

## Layers

```
Features/   → SwiftUI Views + @Observable ViewModels (screen-level state)
DesignSystem/ → Reusable visual language (theme, components, animations)
Core/       → Protocol-first services: Voice, AI, Persistence, Networking
App/        → Composition root: AppEnvironment + @main entry point
```

### Views + ViewModels

Each feature under `Features/` pairs a SwiftUI `View` with an `@Observable`
ViewModel:

- The View owns its ViewModel via `@State private var viewModel = ...`.
- The ViewModel exposes plain `var` properties (no `@Published`) and
  `async` methods.
- Long-running or streaming work (AI responses, live transcription, audio
  levels) is modeled with `AsyncStream` and consumed via `for await` inside
  a `.task { }` modifier, so it's cancelled automatically when the view
  disappears.

This gets most of the ergonomic benefit people reach for TCA for — testable,
observable state — without the reducer/action boilerplate or a third-party
dependency. If Ghost's state machine grows substantially more complex
(e.g. many interacting async processes with strict ordering requirements),
revisit TCA — the ViewModels are already isolated enough that migrating one
feature at a time would be possible.

### Core services are protocols first

Every external integration point Ghost depends on is defined as a protocol
in `Core/`, with exactly one production implementation and one mock used in
tests:

| Protocol | Production implementation | Purpose |
|---|---|---|
| `SpeechRecognizer` | `SFSpeechRecognizerAdapter` | Speech-to-text |
| `SpeechSynthesizer` | `AVSpeechSynthesizerAdapter` | Text-to-speech |
| `AIConversationService` | (pluggable — see below) | LLM chat / streaming responses |
| `ConversationStore` | `SwiftDataConversationStore` | Local persistence |

No AI or voice provider has been locked in yet. `AIConversationService` and
`SpeechRecognizer`/`SpeechSynthesizer` are deliberately provider-agnostic —
swapping in OpenAI's Realtime API, ElevenLabs, Whisper, or a fully on-device
pipeline should mean writing one new adapter file and updating
`AppEnvironment`, not touching any View or ViewModel.

### Composition root

`AppEnvironment` (in `App/AppEnvironment.swift`) is a plain struct that
constructs the concrete service implementations once, at app launch, and
hands protocol-typed references down to feature ViewModels via
initializers. It is intentionally not a DI framework — just constructor
injection — so it stays easy to read and easy to substitute mocks in
previews and tests.

### Persistence

`SwiftData` is used for local conversation history (`Core/Persistence`) —
first-party, no dependency, and it integrates cleanly with `@Observable`
query results.

### Design system

`DesignSystem/` holds the dark, atmospheric visual language as reusable,
non-feature-specific building blocks (`Theme`, `Colors`, `Typography`,
`Components/`, `Animations/`) so every feature screen pulls from the same
palette and motion language instead of redefining it.

## Deployment target

iOS 17.0 — required for `@Observable` and `SwiftData`.
