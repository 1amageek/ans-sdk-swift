public struct Event: Sendable, Hashable, Identifiable {
    public let id: String
    public let type: WireValue
    public let createdAt: String?
    public let expiresAt: String?
    public let agentID: Agent.ID?
    public let name: Name?
    public let host: Host?
    public let version: Version?
    public let providerID: String?
    public let endpoints: [Endpoint]

    public init(
        id: String,
        type: WireValue,
        createdAt: String? = nil,
        expiresAt: String? = nil,
        agentID: Agent.ID? = nil,
        name: Name? = nil,
        host: Host? = nil,
        version: Version? = nil,
        providerID: String? = nil,
        endpoints: [Endpoint] = []
    ) {
        self.id = id
        self.type = type
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.agentID = agentID
        self.name = name
        self.host = host
        self.version = version
        self.providerID = providerID
        self.endpoints = endpoints
    }
}

public struct EventPage: Sendable, Hashable {
    public let items: [Event]
    public let lastLogID: String?

    public init(items: [Event], lastLogID: String? = nil) {
        self.items = items
        self.lastLogID = lastLogID
    }
}

#if !hasFeature(Embedded)
extension Event: Codable {}
extension EventPage: Codable {}
#endif
