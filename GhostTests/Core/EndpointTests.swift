import Foundation
@testable import Ghost
import Testing

struct EndpointTests {
    @Test
    func urlRequestAppendsQueryItemsWhenPresent() {
        let endpoint = Endpoint(
            path: "/v1beta/models/gemini-2.5-pro:streamGenerateContent",
            method: "POST",
            queryItems: [URLQueryItem(name: "alt", value: "sse")]
        )

        let request = endpoint.urlRequest(baseURL: URL(string: "https://generativelanguage.googleapis.com")!)

        #expect(request.url?.absoluteString ==
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:streamGenerateContent?alt=sse")
        #expect(request.httpMethod == "POST")
    }

    @Test
    func urlRequestOmitsQueryStringWhenNoItems() {
        let endpoint = Endpoint(path: "/v1/messages", method: "POST")

        let request = endpoint.urlRequest(baseURL: URL(string: "https://api.anthropic.com")!)

        #expect(request.url?.absoluteString == "https://api.anthropic.com/v1/messages")
    }
}
