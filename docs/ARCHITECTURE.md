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
| `SpeechRecognizer` | `SFSpeechRecognizerAdapter` | Speech-to-text (bridges to `TranscriptionService`) |
| `SpeechSynthesizer` | `AVSpeechSynthesizerAdapter` | Text-to-speech |
| `AIConversationService` | (pluggable — see below) | LLM chat / streaming responses |
| `ConversationStore` | `SwiftDataConversationStore` | Local persistence |
| `HealthDataProvider` | `HealthKitDataProvider` | Recent HealthKit metrics (steps, heart rate, sleep) |
| `TimelineStore` | `SwiftDataTimelineStore` | Local persistence for the shared timeline |

`AIConversationService` ships four adapters — `AnthropicAIConversationService`,
`OpenAIAIConversationService`, `GrokAIConversationService`, and
`GeminiAIConversationService` — selected per `AIProvider` case. The user
picks one (and saves its key) in Settings, plus a model — either from
`AIProvider.availableModels`'s short curated list or any free-text model
ID the provider supports, defaulting to `AIProvider.defaultModel`.
`RoutingAIConversationService` (the instance `AppEnvironment.live()`
actually hands out) reads both selections fresh on every request via
`AppEnvironment.makeAIConversationService(provider:model:apiKeyStore:)`,
so switching providers, picking a different model, or saving a new key
applies to the next message without relaunching. `APIKeyStore` keeps a
separate Keychain entry per provider (model choice isn't sensitive, so it
lives in `UserPreferencesStore`/`UserDefaults` instead, one entry per
provider so switching providers doesn't lose the other's pick). Adding a
fifth provider (ElevenLabs for voice, a self-hosted
model, ...) means one new adapter file, an `AIProvider` case, and a switch
arm — not touching any View or ViewModel. `SpeechRecognizer`/`SpeechSynthesizer`
remain single-adapter today (on-device `Speech`/`AVSpeechSynthesizer`) but
are equally provider-agnostic by design.

### Transcription pipeline

`Core/Voice/Transcription/` holds the voice-to-text pipeline as three
independently swappable pieces, composed by `DefaultTranscriptionService`:

| Protocol | Production implementation | Purpose |
|---|---|---|
| `AudioCapture` | `MicrophoneAudioCapture` | Mic → `AVAudioPCMBuffer` stream (`AVAudioEngine`) |
| `TranscriptionProvider` | `AppleSpeechTranscriptionProvider` | Audio buffers → raw transcript text (on-device `Speech` framework) |
| — | `TranscriptCleaner` | Raw text → clean text (whitespace, filler words, capitalization) |

`AudioCapture` and `TranscriptionProvider` don't know about each other —
capture only knows about producing buffers, the provider only knows about
turning audio into text — so either swaps independently: a file-based
`AudioCapture` for batch/offline transcription, or a server-based
`TranscriptionProvider` (Whisper, Deepgram, ...) for higher accuracy,
without touching the other piece or `TranscriptionService` itself.
`TranscriptCleaner` is a pure function so its rules can evolve without
touching capture or recognition at all.

`SFSpeechRecognizerAdapter` (the `SpeechRecognizer` implementation
`VoiceEngine` depends on) is a thin bridge: it owns a
`TranscriptionService` and translates its `.partial`/`.final` text events
into `VoiceEvent`, forwarding captured audio levels as `.amplitude`. That
keeps `VoiceEngine`, `ConversationViewModel`, and the waveform UI
completely unaware that the transcription pipeline underneath changed.

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

Alongside conversation history, `Core/Persistence` holds the **unified
timeline** (`TimelineEvent`/`TimelineStore`): a generic
timestamp/type/payload shape that any external data source normalizes
into, so Ghost can reference it in conversation. HealthKit
(`Core/Health`) is the first source; `ConversationViewModel.start()`
syncs recent metrics onto it and summarizes them (see
`HealthTimelineSummarizer`) into a short natural-language note folded
into the system prompt via `PromptBuilder`. A future data source (e.g.
calendar) plugs in the same way: a `Core/<Source>` normalizer that writes
`TimelineEvent`s, no changes to persistence itself.

### Design system

`DesignSystem/` holds the dark, atmospheric visual language as reusable,
non-feature-specific building blocks (`Theme`, `Colors`, `Typography`,
`Components/`, `Animations/`) so every feature screen pulls from the same
palette and motion language instead of redefining it.

## Deployment target

iOS 17.0 — required for `@Observable` and `SwiftData`.
