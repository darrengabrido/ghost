import Foundation

enum NetworkError: LocalizedError {
    case invalidResponse
    case httpStatus(Int)
    case decoding(Error)
    case missingConfiguration(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "Ghost received an unexpected response."
        case .httpStatus(let code):
            "Ghost's request failed (HTTP \(code))."
        case .decoding:
            "Ghost couldn't understand the response it got back."
        case .missingConfiguration(let key):
            "Missing configuration for \(key) — check Secrets.xcconfig."
        }
    }
}
