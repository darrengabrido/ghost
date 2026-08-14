import Foundation

/// Every screen reachable from the onboarding root. Kept as a flat enum
/// since Ghost's navigation is shallow by design — voice-first apps
/// shouldn't need deep hierarchies.
enum Route: Hashable {
    case conversation
    case history
    case settings
}
