/// Deterministic RNG so the mote field is identical on every launch and in
/// every preview. A drifting particle field that reshuffles each cold start
/// reads as noise; one that's always the same reads as a place.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var mix = state
        mix = (mix ^ (mix >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mix = (mix ^ (mix >> 27)) &* 0x94D0_49BB_1331_11EB
        return mix ^ (mix >> 31)
    }
}
