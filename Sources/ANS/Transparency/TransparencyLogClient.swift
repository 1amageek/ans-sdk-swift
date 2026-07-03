#if !hasFeature(Embedded)
public struct TransparencyLogClient: TransparencyLog {
    private let client: Client

    public init(client: Client) {
        self.client = client
    }

    public func badge(for agentID: Agent.ID) async throws(any Error) -> Badge {
        try await client.getFromTransparencyLog(Badge.self, path: client.paths.badgePath(for: agentID))
    }

    public func badge(at uri: URI) async throws(any Error) -> Badge {
        let response = try await client.send(Request(method: .get, uri: uri, headers: client.jsonHeaders()))
        guard response.statusCode >= 200, response.statusCode < 300 else {
            throw HTTPError(statusCode: response.statusCode, body: response.body)
        }
        return try JSON.decode(Badge.self, from: response.body)
    }

    public func audit(agentID: Agent.ID, page: Page?) async throws(any Error) -> TransparencyAudit {
        let queryItems = [
            ("limit", page?.limit.map(String.init)),
            ("offset", page?.offset.map(String.init)),
        ]
        return try await client.getFromTransparencyLog(
            TransparencyAudit.self,
            path: client.paths.auditPath(for: agentID),
            queryItems: queryItems
        )
    }

    public func checkpoint() async throws(any Error) -> Checkpoint {
        try await client.getFromTransparencyLog(Checkpoint.self, path: client.paths.checkpointPath)
    }

    public func checkpointHistory(page: Page?) async throws(any Error) -> CheckpointHistory {
        let queryItems = [
            ("limit", page?.limit.map(String.init)),
            ("offset", page?.offset.map(String.init)),
        ]
        return try await client.getFromTransparencyLog(
            CheckpointHistory.self,
            path: client.paths.checkpointHistoryPath,
            queryItems: queryItems
        )
    }

    public func schema(version: String) async throws(any Error) -> [UInt8] {
        let uri = try client.configuration.transparencyLogBaseURI
            .okOrMissingTransparencyLogBaseURI()
            .appending(path: client.paths.schemaPath(version: version))
        let response = try await client.send(Request(method: .get, uri: uri, headers: client.jsonHeaders()))
        guard response.statusCode >= 200, response.statusCode < 300 else {
            throw HTTPError(statusCode: response.statusCode, body: response.body)
        }
        return response.body
    }

    public func receipt(agentID: Agent.ID) async throws(any Error) -> [UInt8] {
        try await raw(path: client.paths.receiptPath(for: agentID))
    }

    public func statusToken(agentID: Agent.ID) async throws(any Error) -> [UInt8] {
        try await raw(path: client.paths.statusTokenPath(for: agentID))
    }

    public func rootKeys() async throws(any Error) -> [RootKey] {
        let uri = try client.configuration.transparencyLogBaseURI
            .okOrMissingTransparencyLogBaseURI()
            .appending(path: "/root-keys")
        let response = try await client.send(Request(method: .get, uri: uri))
        guard response.statusCode >= 200, response.statusCode < 300 else {
            throw HTTPError(statusCode: response.statusCode, body: response.body)
        }

        do {
            return try JSON.decode([RootKey].self, from: response.body)
        } catch {
            let text = String(decoding: response.body, as: UTF8.self)
            var keys: [RootKey] = []
            for line in text.split(whereSeparator: { $0 == "\n" || $0 == "\r" }) {
                let trimmed = String(line).trimmingANSWhitespace()
                if trimmed.isEmpty {
                    continue
                }
                keys.append(try RootKey(c2sp: trimmed))
            }
            guard !keys.isEmpty else {
                throw SCITTError.invalidToken("No root keys found")
            }
            return keys
        }
    }

    public func identityBadge(for identityID: Identity.ID) async throws(any Error) -> TransparencyRecord {
        try await client.getFromTransparencyLog(
            TransparencyRecord.self,
            path: client.paths.identityBadgePath(for: identityID)
        )
    }

    public func identityAudit(identityID: Identity.ID, page: Page?) async throws(any Error) -> TransparencyRecordAudit {
        let queryItems = [
            ("limit", page?.limit.map(String.init)),
            ("offset", page?.offset.map(String.init)),
        ]
        return try await client.getFromTransparencyLog(
            TransparencyRecordAudit.self,
            path: client.paths.identityAuditPath(for: identityID),
            queryItems: queryItems
        )
    }

    public func identityReceipt(identityID: Identity.ID) async throws(any Error) -> [UInt8] {
        try await raw(path: client.paths.identityReceiptPath(for: identityID))
    }

    public func identityAgents(identityID: Identity.ID, page: Page?) async throws(any Error) -> Identity.LinkedAgentPage {
        let queryItems = [
            ("limit", page?.limit.map(String.init)),
            ("offset", page?.offset.map(String.init)),
        ]
        return try await client.getFromTransparencyLog(
            Identity.LinkedAgentPage.self,
            path: client.paths.identityAgentsPath(for: identityID),
            queryItems: queryItems
        )
    }

    public func agentIdentities(agentID: Agent.ID, page: Page?) async throws(any Error) -> Identity.LinkedIdentityPage {
        let queryItems = [
            ("limit", page?.limit.map(String.init)),
            ("offset", page?.offset.map(String.init)),
        ]
        return try await client.getFromTransparencyLog(
            Identity.LinkedIdentityPage.self,
            path: client.paths.agentIdentitiesPath(for: agentID),
            queryItems: queryItems
        )
    }

    public func agentIdentityHistory(agentID: Agent.ID, page: Page?) async throws(any Error) -> TransparencyRecordAudit {
        let queryItems = [
            ("limit", page?.limit.map(String.init)),
            ("offset", page?.offset.map(String.init)),
        ]
        return try await client.getFromTransparencyLog(
            TransparencyRecordAudit.self,
            path: client.paths.agentIdentityHistoryPath(for: agentID),
            queryItems: queryItems
        )
    }

    public func rawCheckpoint() async throws(any Error) -> [UInt8] {
        try await raw(path: client.paths.rawCheckpointPath)
    }

    public func tile(level: Int, index: Int) async throws(any Error) -> [UInt8] {
        try await raw(path: client.paths.tilePath(level: level, index: index))
    }

    public func partialTile(level: Int, index: Int, width: Int) async throws(any Error) -> [UInt8] {
        try await raw(path: client.paths.partialTilePath(level: level, index: index, width: width))
    }

    public func entryTile(index: Int) async throws(any Error) -> [UInt8] {
        try await raw(path: client.paths.entryTilePath(index: index))
    }

    public func partialEntryTile(index: Int, width: Int) async throws(any Error) -> [UInt8] {
        try await raw(path: client.paths.partialEntryTilePath(index: index, width: width))
    }

    private func raw(path: String) async throws(any Error) -> [UInt8] {
        let uri = try client.configuration.transparencyLogBaseURI
            .okOrMissingTransparencyLogBaseURI()
            .appending(path: path)
        let response = try await client.send(Request(method: .get, uri: uri))
        guard response.statusCode >= 200, response.statusCode < 300 else {
            throw HTTPError(statusCode: response.statusCode, body: response.body)
        }
        return response.body
    }
}

private extension String {
    func trimmingANSWhitespace() -> String {
        let bytes = Array(utf8)
        var start = 0
        var end = bytes.count
        while start < end, bytes[start].isANSWhitespace {
            start += 1
        }
        while end > start, bytes[end - 1].isANSWhitespace {
            end -= 1
        }
        return String(decoding: bytes[start..<end], as: UTF8.self)
    }
}

private extension UInt8 {
    var isANSWhitespace: Bool {
        self == 9 || self == 10 || self == 13 || self == 32
    }
}

private extension Optional where Wrapped == URI {
    func okOrMissingTransparencyLogBaseURI() throws(ValidationError) -> URI {
        guard let value = self else {
            throw .missingTransparencyLogBaseURI
        }
        return value
    }
}
#endif
