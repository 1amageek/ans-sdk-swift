public struct Search: Sendable, Hashable {
    public struct Result: Sendable, Hashable {
        public let agents: [Agent]
        public let totalCount: Int?
        public let returnedCount: Int?
        public let hasMore: Bool
        public let nextCursor: String?

        public init(
            agents: [Agent],
            totalCount: Int? = nil,
            returnedCount: Int? = nil,
            hasMore: Bool = false,
            nextCursor: String? = nil
        ) {
            self.agents = agents
            self.totalCount = totalCount
            self.returnedCount = returnedCount
            self.hasMore = hasMore
            self.nextCursor = nextCursor
        }
    }

    public let host: Host?
    public let displayName: String?
    public let version: VersionRequirement?
    public let protocolKind: Endpoint.ProtocolKind?
    public let statuses: [Registration.Status]
    public let page: Page?

    public init(
        host: Host? = nil,
        displayName: String? = nil,
        version: VersionRequirement? = nil,
        protocolKind: Endpoint.ProtocolKind? = nil,
        statuses: [Registration.Status] = [],
        page: Page? = nil
    ) {
        self.host = host
        self.displayName = displayName
        self.version = version
        self.protocolKind = protocolKind
        self.statuses = statuses
        self.page = page
    }
}

#if !hasFeature(Embedded)
extension Search: Codable {}
extension Search.Result: Codable {}
#endif
