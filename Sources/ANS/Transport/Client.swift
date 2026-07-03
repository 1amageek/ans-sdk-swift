#if !hasFeature(Embedded)
public struct Client: Sendable {
    public let configuration: Configuration
    public let transport: any Transport
    public let paths: Paths

    public init(configuration: Configuration, transport: any Transport, paths: Paths = Paths()) {
        self.configuration = configuration
        self.transport = transport
        self.paths = paths
    }

    public func send(_ request: Request) async throws(any Error) -> Response {
        try await transport.send(request)
    }

    public func get<Value: Decodable>(_ type: Value.Type, path: String, queryItems: [(String, String?)] = []) async throws(any Error) -> Value {
        let uri = try configuration.registryBaseURI.appending(path: path, queryItems: queryItems)
        let response = try await send(Request(method: .get, uri: uri, headers: authorizedJSONHeaders()))
        return try decode(type, from: response)
    }

    public func post<RequestBody: Encodable, Value: Decodable>(
        _ type: Value.Type,
        path: String,
        body: RequestBody
    ) async throws(any Error) -> Value {
        let uri = try configuration.registryBaseURI.appending(path: path)
        let response = try await send(Request(
            method: .post,
            uri: uri,
            headers: authorizedJSONHeaders(),
            body: try JSON.encode(body)
        ))
        return try decode(type, from: response)
    }

    public func post<Value: Decodable>(_ type: Value.Type, path: String) async throws(any Error) -> Value {
        let uri = try configuration.registryBaseURI.appending(path: path)
        let response = try await send(Request(method: .post, uri: uri, headers: authorizedJSONHeaders()))
        return try decode(type, from: response)
    }

    public func put<RequestBody: Encodable, Value: Decodable>(
        _ type: Value.Type,
        path: String,
        body: RequestBody
    ) async throws(any Error) -> Value {
        let uri = try configuration.registryBaseURI.appending(path: path)
        let response = try await send(Request(
            method: .put,
            uri: uri,
            headers: authorizedJSONHeaders(),
            body: try JSON.encode(body)
        ))
        return try decode(type, from: response)
    }

    public func delete(path: String) async throws(any Error) {
        let uri = try configuration.registryBaseURI.appending(path: path)
        let response = try await send(Request(method: .delete, uri: uri, headers: authorizedJSONHeaders()))
        guard response.statusCode >= 200, response.statusCode < 300 else {
            throw HTTPError(statusCode: response.statusCode, body: response.body)
        }
    }

    public func getFromTransparencyLog<Value: Decodable>(
        _ type: Value.Type,
        path: String,
        queryItems: [(String, String?)] = []
    ) async throws(any Error) -> Value {
        guard let baseURI = configuration.transparencyLogBaseURI else {
            throw ValidationError.missingTransparencyLogBaseURI
        }
        let uri = try baseURI.appending(path: path, queryItems: queryItems)
        let response = try await send(Request(method: .get, uri: uri, headers: jsonHeaders()))
        return try decode(type, from: response)
    }

    public func authorizedHeaders(_ headers: [String: String] = [:]) -> [String: String] {
        guard let authorization = configuration.authorization else {
            return headers
        }

        var headers = headers
        headers["Authorization"] = authorization.headerValue
        return headers
    }

    public func jsonHeaders() -> [String: String] {
        [
            "Accept": "application/json",
            "Content-Type": "application/json",
        ]
    }

    public func authorizedJSONHeaders() -> [String: String] {
        authorizedHeaders(jsonHeaders())
    }

    private func decode<Value: Decodable>(_ type: Value.Type, from response: Response) throws(any Error) -> Value {
        guard response.statusCode >= 200, response.statusCode < 300 else {
            throw HTTPError(statusCode: response.statusCode, body: response.body)
        }
        return try JSON.decode(type, from: response.body)
    }
}
#endif
