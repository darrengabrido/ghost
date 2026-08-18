import Foundation

struct Endpoint {
    var path: String
    var method: String = "GET"
    var headers: [String: String] = [:]
    var queryItems: [URLQueryItem] = []
    var body: Data?

    func urlRequest(baseURL: URL) -> URLRequest {
        let pathURL = baseURL.appendingPathComponent(path)
        var components = URLComponents(url: pathURL, resolvingAgainstBaseURL: false)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        var request = URLRequest(url: components?.url ?? pathURL)
        request.httpMethod = method
        request.httpBody = body
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        return request
    }
}
