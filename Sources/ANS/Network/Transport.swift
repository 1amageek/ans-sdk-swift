import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum Method: String, Sendable, Codable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public struct Request: Sendable, Hashable {
    public let method: Method
    public let url: URL
    public let headers: [String: String]
    public let body: Data?

    public init(method: Method, url: URL, headers: [String: String] = [:], body: Data? = nil) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
    }
}

public struct Response: Sendable, Hashable {
    public let statusCode: Int
    public let headers: [String: String]
    public let body: Data

    public init(statusCode: Int, headers: [String: String] = [:], body: Data = Data()) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }
}

public protocol Transport: Sendable {
    func send(_ request: Request) async throws -> Response
}

public actor NetworkTransport: Transport {
    private let session: URLSession

    public init(configuration: URLSessionConfiguration = .default) {
        self.session = URLSession(configuration: configuration)
    }

    public func send(_ request: Request) async throws -> Response {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw TransportError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TransportError("Response was not HTTP")
        }

        var headers: [String: String] = [:]
        for (key, value) in httpResponse.allHeaderFields {
            guard let key = key as? String else { continue }
            headers[key] = String(describing: value)
        }

        return Response(statusCode: httpResponse.statusCode, headers: headers, body: data)
    }
}

public enum Credential: Sendable, Hashable {
    case jwt(String)
    case apiKey(key: String, secret: String)
    case bearer(String)
    case none

    var authorizationHeader: String? {
        switch self {
        case let .jwt(token):
            return "sso-jwt \(token)"
        case let .apiKey(key, secret):
            return "sso-key \(key):\(secret)"
        case let .bearer(token):
            return "Bearer \(token)"
        case .none:
            return nil
        }
    }
}

extension Credential: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .jwt:
            return "Credential.jwt(<redacted>)"
        case .apiKey:
            return "Credential.apiKey(<redacted>)"
        case .bearer:
            return "Credential.bearer(<redacted>)"
        case .none:
            return "Credential.none"
        }
    }
}

public struct Configuration: Sendable, Hashable {
    public let registryBaseURL: URL
    public let transparencyBaseURL: URL
    public let credential: Credential
    public let paths: Paths
    public let additionalHeaders: [String: String]

    public init(
        registryBaseURL: URL,
        transparencyBaseURL: URL? = nil,
        credential: Credential = .none,
        paths: Paths = .v1,
        additionalHeaders: [String: String] = [:]
    ) {
        self.registryBaseURL = registryBaseURL
        self.transparencyBaseURL = transparencyBaseURL ?? registryBaseURL
        self.credential = credential
        self.paths = paths
        self.additionalHeaders = additionalHeaders
    }
}
