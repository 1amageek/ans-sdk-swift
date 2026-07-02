import Foundation

public struct Search: Sendable, Hashable, Codable {
    public struct Result: Sendable, Hashable, Codable {
        public let agents: [Agent]
        public let nextCursor: String?

        public init(agents: [Agent], nextCursor: String? = nil) {
            self.agents = agents
            self.nextCursor = nextCursor
        }
    }

    public let host: Host?
    public let displayName: String?
    public let protocolKind: Endpoint.ProtocolKind?
    public let transport: Endpoint.TransportKind?
    public let tags: [String]
    public let status: Registration.Status?
    public let page: Page?

    public init(
        host: Host? = nil,
        displayName: String? = nil,
        protocolKind: Endpoint.ProtocolKind? = nil,
        transport: Endpoint.TransportKind? = nil,
        tags: [String] = [],
        status: Registration.Status? = nil,
        page: Page? = nil
    ) {
        self.host = host
        self.displayName = displayName
        self.protocolKind = protocolKind
        self.transport = transport
        self.tags = tags
        self.status = status
        self.page = page
    }
}
