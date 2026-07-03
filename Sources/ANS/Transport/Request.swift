public struct Request: Sendable, Hashable {
    public enum Method: String, Sendable, Hashable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }

    public let method: Method
    public let uri: URI
    public let headers: [String: String]
    public let body: [UInt8]

    public init(method: Method, uri: URI, headers: [String: String] = [:], body: [UInt8] = []) {
        self.method = method
        self.uri = uri
        self.headers = headers
        self.body = body
    }
}

#if !hasFeature(Embedded)
extension Request.Method: Codable {}
#endif
