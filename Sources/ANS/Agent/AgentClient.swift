#if !hasFeature(Embedded)
public struct AgentResponse: Sendable, Hashable {
    public let response: Response
    public let outcome: Outcome?

    public init(response: Response, outcome: Outcome?) {
        self.response = response
        self.outcome = outcome
    }
}

public enum AgentClientError: Error, Sendable, Equatable {
    case verificationRequiresHTTPS(String)
    case missingPeerCertificate(Host)
    case verificationRejected(Outcome)
    case invalidResponseStatus(Int)
}

public struct AgentClient: Sendable {
    private let transport: any Transport
    private let verifier: Verifier
    private let verifyServer: Bool
    private let scittPolicy: SCITTPolicy

    public init(
        transport: any Transport,
        verifier: Verifier,
        verifyServer: Bool = true,
        scittPolicy: SCITTPolicy = .withBadgeFallback
    ) {
        self.transport = transport
        self.verifier = verifier
        self.verifyServer = verifyServer
        self.scittPolicy = scittPolicy
    }

    @discardableResult
    public func prefetch(host: Host) async throws(any Error) -> Badge? {
        try await verifier.prefetch(host: host)
    }

    public func get(_ uri: URI, headers: [String: String] = [:]) async throws(any Error) -> AgentResponse {
        try await send(Request(method: .get, uri: uri, headers: headers))
    }

    public func post(_ uri: URI, headers: [String: String] = [:], body: [UInt8] = []) async throws(any Error) -> AgentResponse {
        try await send(Request(method: .post, uri: uri, headers: headers, body: body))
    }

    public func put(_ uri: URI, headers: [String: String] = [:], body: [UInt8] = []) async throws(any Error) -> AgentResponse {
        try await send(Request(method: .put, uri: uri, headers: headers, body: body))
    }

    public func delete(_ uri: URI, headers: [String: String] = [:]) async throws(any Error) -> AgentResponse {
        try await send(Request(method: .delete, uri: uri, headers: headers))
    }

    public func send(_ request: Request) async throws(any Error) -> AgentResponse {
        if verifyServer {
            guard request.uri.scheme == "https" else {
                throw AgentClientError.verificationRequiresHTTPS(request.uri.rawValue)
            }
            _ = try await verifier.prefetch(host: request.uri.host)
        }

        let response = try await transport.send(request)
        guard verifyServer else {
            return AgentResponse(response: response, outcome: nil)
        }

        guard let certificateDER = response.peerCertificateDER else {
            throw AgentClientError.missingPeerCertificate(request.uri.host)
        }
        let certificate = try CertificateIdentity(derBytes: certificateDER)

        let scittHeaders = try SCITTHeaders(httpHeaders: response.headers)
        let outcome: Outcome
        if scittHeaders.isEmpty, scittPolicy == .withBadgeFallback {
            outcome = try await verifier.verifyServer(host: request.uri.host, certificate: certificate)
        } else {
            outcome = try await verifier.verifyServerWithSCITT(
                host: request.uri.host,
                certificate: certificate,
                headers: scittHeaders,
                scittPolicy: scittPolicy
            )
        }

        guard outcome.allowsConnection else {
            throw AgentClientError.verificationRejected(outcome)
        }

        return AgentResponse(response: response, outcome: outcome)
    }

    public func getJSON<Value: Decodable>(_ type: Value.Type, uri: URI, headers: [String: String] = [:]) async throws(any Error) -> (Value, AgentResponse) {
        let agentResponse = try await get(uri, headers: headers)
        let value = try decodeJSON(type, from: agentResponse.response)
        return (value, agentResponse)
    }

    public func postJSON<RequestBody: Encodable, Value: Decodable>(
        _ type: Value.Type,
        uri: URI,
        body: RequestBody,
        headers: [String: String] = [:]
    ) async throws(any Error) -> (Value, AgentResponse) {
        var jsonHeaders = headers
        jsonHeaders["Content-Type"] = "application/json"
        jsonHeaders["Accept"] = "application/json"
        let agentResponse = try await post(uri, headers: jsonHeaders, body: try JSON.encode(body))
        let value = try decodeJSON(type, from: agentResponse.response)
        return (value, agentResponse)
    }

    public func putJSON<RequestBody: Encodable, Value: Decodable>(
        _ type: Value.Type,
        uri: URI,
        body: RequestBody,
        headers: [String: String] = [:]
    ) async throws(any Error) -> (Value, AgentResponse) {
        var jsonHeaders = headers
        jsonHeaders["Content-Type"] = "application/json"
        jsonHeaders["Accept"] = "application/json"
        let agentResponse = try await put(uri, headers: jsonHeaders, body: try JSON.encode(body))
        let value = try decodeJSON(type, from: agentResponse.response)
        return (value, agentResponse)
    }

    private func decodeJSON<Value: Decodable>(_ type: Value.Type, from response: Response) throws(any Error) -> Value {
        guard response.statusCode >= 200, response.statusCode < 300 else {
            throw AgentClientError.invalidResponseStatus(response.statusCode)
        }
        return try JSON.decode(type, from: response.body)
    }
}
#endif
