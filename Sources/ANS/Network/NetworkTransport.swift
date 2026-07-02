import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

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
