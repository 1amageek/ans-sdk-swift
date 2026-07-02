import Foundation

public struct Client: Registry, TransparencyLog, Sendable {
    public let configuration: Configuration
    private let transport: any Transport

    public init(configuration: Configuration, transport: any Transport = NetworkTransport()) {
        self.configuration = configuration
        self.transport = transport
    }

    public func register(_ request: Registration.Request) async throws -> Registration.Pending {
        try await sendJSON(
            method: .post,
            baseURL: configuration.registryBaseURL,
            path: configuration.paths.registerAgent(),
            body: request,
            as: Registration.Pending.self
        )
    }

    public func agent(id: Agent.ID) async throws -> Agent {
        try await send(
            method: .get,
            baseURL: configuration.registryBaseURL,
            path: configuration.paths.agent(id),
            as: Agent.self
        )
    }

    public func search(_ query: Search) async throws -> Search.Result {
        try await send(
            method: .get,
            baseURL: configuration.registryBaseURL,
            path: configuration.paths.searchAgents(),
            queryItems: searchQueryItems(query),
            as: Search.Result.self
        )
    }

    public func resolve(host: Host, version: VersionRequirement?) async throws -> Resolution {
        var items = [URLQueryItem(name: "agentHost", value: host.rawValue)]
        if let version {
            items.append(URLQueryItem(name: "version", value: version.rawValue))
        }
        return try await send(
            method: .get,
            baseURL: configuration.registryBaseURL,
            path: configuration.paths.resolveAgent(),
            queryItems: items,
            as: Resolution.self
        )
    }

    public func verifyACME(agent id: Agent.ID) async throws -> Agent {
        try await send(
            method: .post,
            baseURL: configuration.registryBaseURL,
            path: configuration.paths.verifyACME(id),
            as: Agent.self
        )
    }

    public func verifyDNS(agent id: Agent.ID) async throws -> Agent {
        try await send(
            method: .post,
            baseURL: configuration.registryBaseURL,
            path: configuration.paths.verifyDNS(id),
            as: Agent.self
        )
    }

    public func revoke(agent id: Agent.ID, reason: Revocation.Reason) async throws -> Agent {
        let request = Revocation(reason: reason)
        return try await sendJSON(
            method: .post,
            baseURL: configuration.registryBaseURL,
            path: configuration.paths.revoke(id),
            body: request,
            as: Agent.self
        )
    }

    public func identityCertificates(agent id: Agent.ID) async throws -> [Certificate] {
        try await send(
            method: .get,
            baseURL: configuration.registryBaseURL,
            path: configuration.paths.identityCertificates(id),
            as: [Certificate].self
        )
    }

    public func serverCertificates(agent id: Agent.ID) async throws -> [Certificate] {
        try await send(
            method: .get,
            baseURL: configuration.registryBaseURL,
            path: configuration.paths.serverCertificates(id),
            as: [Certificate].self
        )
    }

    public func events(agent id: Agent.ID) async throws -> Audit {
        try await audit(for: id, page: nil)
    }

    public func badge(for agent: Agent.ID) async throws -> Badge {
        try await send(
            method: .get,
            baseURL: configuration.transparencyBaseURL,
            path: configuration.paths.badge(agent),
            authenticated: false,
            as: Badge.self
        )
    }

    public func badge(at url: URL) async throws -> Badge {
        try await send(request: Request(method: .get, url: url, headers: readOnlyHeaders()), as: Badge.self)
    }

    public func audit(for agent: Agent.ID, page: Page?) async throws -> Audit {
        try await send(
            method: .get,
            baseURL: configuration.transparencyBaseURL,
            path: configuration.paths.audit(agent),
            queryItems: pageItems(page),
            authenticated: false,
            as: Audit.self
        )
    }

    public func receipt(for agent: Agent.ID) async throws -> Receipt {
        let body = try await sendRaw(
            method: .get,
            baseURL: configuration.transparencyBaseURL,
            path: configuration.paths.receipt(agent),
            authenticated: false
        )
        return Receipt(bytes: body)
    }

    public func statusToken(for agent: Agent.ID) async throws -> Token {
        let body = try await sendRaw(
            method: .get,
            baseURL: configuration.transparencyBaseURL,
            path: configuration.paths.statusToken(agent),
            authenticated: false
        )
        return Token(bytes: body)
    }

    public func checkpoint() async throws -> Checkpoint {
        try await send(
            method: .get,
            baseURL: configuration.transparencyBaseURL,
            path: configuration.paths.checkpoint(),
            authenticated: false,
            as: Checkpoint.self
        )
    }

    public func checkpointHistory(page: Page?) async throws -> [Checkpoint] {
        try await send(
            method: .get,
            baseURL: configuration.transparencyBaseURL,
            path: configuration.paths.checkpointHistory(),
            queryItems: pageItems(page),
            authenticated: false,
            as: [Checkpoint].self
        )
    }

    public func schema(version: String) async throws -> Data {
        try await sendRaw(
            method: .get,
            baseURL: configuration.transparencyBaseURL,
            path: configuration.paths.schema(version),
            authenticated: false
        )
    }

    public func rootKeys() async throws -> [RootKey] {
        let body = try await sendRaw(
            method: .get,
            baseURL: configuration.transparencyBaseURL,
            path: configuration.paths.rootKeys(),
            authenticated: false
        )
        guard let text = String(data: body, encoding: .utf8) else {
            throw ParsingError("Root keys response was not UTF-8")
        }
        return try text
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .filter { !$0.isEmpty }
            .map(RootKey.init(line:))
    }

    private func send<Value: Decodable>(
        method: Method,
        baseURL: URL,
        path: String,
        queryItems: [URLQueryItem] = [],
        authenticated: Bool = true,
        as type: Value.Type
    ) async throws -> Value {
        let url = baseURL.ansAppendingPath(path).ansAppendingQuery(queryItems)
        let headers = authenticated ? defaultHeaders() : readOnlyHeaders()
        return try await send(request: Request(method: method, url: url, headers: headers), as: type)
    }

    private func sendJSON<Body: Encodable, Value: Decodable>(
        method: Method,
        baseURL: URL,
        path: String,
        body: Body,
        as type: Value.Type
    ) async throws -> Value {
        var headers = defaultHeaders()
        headers["Content-Type"] = "application/json"
        let encoded = try JSONEncoder.ans.encode(body)
        let url = baseURL.ansAppendingPath(path)
        return try await send(request: Request(method: method, url: url, headers: headers, body: encoded), as: type)
    }

    private func send<Value: Decodable>(request: Request, as type: Value.Type) async throws -> Value {
        let response = try await transport.send(request)
        guard (200..<300).contains(response.statusCode) else {
            throw ServerError(statusCode: response.statusCode, body: response.body)
        }
        do {
            return try JSONDecoder.ans.decode(Value.self, from: response.body)
        } catch {
            throw ParsingError("Failed to decode response as \(Value.self): \(error.localizedDescription)")
        }
    }

    private func sendRaw(method: Method, baseURL: URL, path: String, authenticated: Bool = true) async throws -> Data {
        let url = baseURL.ansAppendingPath(path)
        let headers = authenticated ? defaultHeaders() : readOnlyHeaders()
        let response = try await transport.send(Request(method: method, url: url, headers: headers))
        guard (200..<300).contains(response.statusCode) else {
            throw ServerError(statusCode: response.statusCode, body: response.body)
        }
        return response.body
    }

    private func defaultHeaders() -> [String: String] {
        var headers = configuration.additionalHeaders
        headers["Accept"] = headers["Accept"] ?? "application/json"
        if let authorization = configuration.credential.authorizationHeader {
            headers["Authorization"] = authorization
        }
        return headers
    }

    private func readOnlyHeaders() -> [String: String] {
        var headers = configuration.additionalHeaders.filter { key, _ in
            key.caseInsensitiveCompare("Authorization") != .orderedSame
        }
        headers["Accept"] = headers["Accept"] ?? "application/json"
        return headers
    }

    private func searchQueryItems(_ query: Search) -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let host = query.host {
            items.append(URLQueryItem(name: "agentHost", value: host.rawValue))
        }
        if let displayName = query.displayName {
            items.append(URLQueryItem(name: "agentDisplayName", value: displayName))
        }
        if let protocolKind = query.protocolKind {
            items.append(URLQueryItem(name: "protocol", value: protocolKind.rawValue))
        }
        if let transport = query.transport {
            items.append(URLQueryItem(name: "transport", value: transport.rawValue))
        }
        for tag in query.tags {
            items.append(URLQueryItem(name: "tag", value: tag))
        }
        if let status = query.status {
            items.append(URLQueryItem(name: "status", value: status.rawValue))
        }
        items.append(contentsOf: pageItems(query.page))
        return items
    }

    private func pageItems(_ page: Page?) -> [URLQueryItem] {
        guard let page else { return [] }
        var items: [URLQueryItem] = []
        if let limit = page.limit {
            items.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if let cursor = page.cursor {
            items.append(URLQueryItem(name: "cursor", value: cursor))
        }
        return items
    }
}

extension JSONEncoder {
    static var ans: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var ans: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
