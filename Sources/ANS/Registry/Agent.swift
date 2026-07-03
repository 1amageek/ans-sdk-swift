public struct Agent: Sendable, Hashable, Identifiable {
    public struct ID: Sendable, Hashable, RawRepresentable, CustomStringConvertible {
        public let rawValue: String

        public var description: String {
            rawValue
        }

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public let id: ID
    public let entryID: Entry.ID?
    public let name: Name?
    public let host: Host
    public let displayName: String
    public let description: String?
    public let version: Version?
    public let status: Registration.Status
    public let endpoints: [Endpoint]
    public let ttl: Int?
    public let registrationTimestamp: String?
    public let lastRenewalTimestamp: String?
    public let links: [Registration.Link]
    public let identities: [Identity.LinkedIdentity]

    public init(
        id: ID,
        entryID: Entry.ID? = nil,
        name: Name? = nil,
        host: Host,
        displayName: String,
        description: String? = nil,
        version: Version? = nil,
        status: Registration.Status,
        endpoints: [Endpoint],
        ttl: Int? = nil,
        registrationTimestamp: String? = nil,
        lastRenewalTimestamp: String? = nil,
        links: [Registration.Link] = [],
        identities: [Identity.LinkedIdentity] = []
    ) {
        self.id = id
        self.entryID = entryID
        self.name = name
        self.host = host
        self.displayName = displayName
        self.description = description
        self.version = version
        self.status = status
        self.endpoints = endpoints
        self.ttl = ttl
        self.registrationTimestamp = registrationTimestamp
        self.lastRenewalTimestamp = lastRenewalTimestamp
        self.links = links
        self.identities = identities
    }

    public struct Page: Sendable, Hashable {
        public let items: [Agent]
        public let returnedCount: Int
        public let limit: Int
        public let nextCursor: String?
        public let hasMore: Bool

        public init(
            items: [Agent],
            returnedCount: Int,
            limit: Int,
            nextCursor: String? = nil,
            hasMore: Bool
        ) {
            self.items = items
            self.returnedCount = returnedCount
            self.limit = limit
            self.nextCursor = nextCursor
            self.hasMore = hasMore
        }
    }
}

#if !hasFeature(Embedded)
extension Agent.ID: Codable {}
extension Agent: Codable {}
extension Agent.Page: Codable {}
#endif
