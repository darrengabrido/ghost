import Foundation

struct Endpoint {
    var path: String
    var method: String = "GET"
    var headers: [String: String] = [:]
    var body: Data?

    func urlRequest(baseURL: URL) -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.httpBody = body
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        return request
    }
}
