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

No AI or voice provider has been locked in yet. `AIConversationService` and
`SpeechRecognizer`/`SpeechSynthesizer` are deliberately provider-agnostic —
swapping in OpenAI's Realtime API, ElevenLabs, Whisper, or a fully on-device
pipeline should mean writing one new adapter file and updating
`AppEnvironment`, not touching any View or ViewModel.

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

`Colors` is two layers: a **palette** naming pigments (`ghostMaple`,
`ghostBone`) and **semantic** aliases naming jobs (`ghostAccent`,
`ghostTextPrimary`). Feature code uses the semantic names.

Red is the identity rather than an accent, which forces one rule worth
knowing before touching a screen: `ghostMaple` is a *field* colour — fills,
glows, glass tints, strokes — and never carries small text, where it sits
at 3.3:1 on the charcoal ground. Red type uses `ghostFlare` (6.3:1). For
the same reason destructive actions can't be signalled by redness alone in
an already-red app, so they pair `ghostCrimson` with a glyph.

Every surface sits on `GhostAtmosphereBackground`: sumi ground, drifting
fog, a `Canvas`-drawn wind of embers, static film grain, vignette. It is
not decoration — Liquid Glass has nothing to refract over a flat fill, so
the atmosphere is what makes the glass read as glass. Its `intensity`
parameter is also the app's primary state signal: the room brightens and
the wind thickens while Ghost is awake.

## Deployment target

iOS 26.0.

`@Observable` and `SwiftData` only need iOS 17, but the visual language is
built on Liquid Glass (`glassEffect`, `GlassEffectContainer`, the `.glass`
and `.glassProminent` button styles), which is iOS 26 and has no backport.
Ghost previously carried a `#if compiler(>=6.2)` + `#available(iOS 26, *)`
double guard with an `.ultraThinMaterial` imitation behind it; maintaining
two visual languages cost more than the older versions were worth for an
app that has not shipped. The guards and the fallback are gone.
