import Foundation

public struct Badge: Sendable, Hashable, Codable {
    public struct Status: CanonicalWireValue, ExpressibleByStringLiteral {
        public let rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: String) {
            self.init(value)
        }

        public static let active = Self("ACTIVE")
        public static let warning = Self("WARNING")
        public static let deprecated = Self("DEPRECATED")
        public static let expired = Self("EXPIRED")
        public static let revoked = Self("REVOKED")
        public static let verified = Self("VERIFIED")

        public var isRejected: Bool {
            self == .expired || self == .revoked
        }
    }

    public let agentID: Agent.ID?
    public let entryID: Entry.ID?
    public let name: Name?
    public let host: Host
    public let status: Status
    public let serverFingerprints: [Fingerprint]
    public let identityFingerprints: [Fingerprint]
    public let proof: Proof?
    public let issuedAt: Date?
    public let expiresAt: Date?
    public let identities: [Identity]
    public let receipt: Receipt?
    public let statusToken: Token?

    public init(
        agentID: Agent.ID? = nil,
        entryID: Entry.ID? = nil,
        name: Name? = nil,
        host: Host,
        status: Status,
        serverFingerprints: [Fingerprint] = [],
        identityFingerprints: [Fingerprint] = [],
        proof: Proof? = nil,
        issuedAt: Date? = nil,
        expiresAt: Date? = nil,
        identities: [Identity] = [],
        receipt: Receipt? = nil,
        statusToken: Token? = nil
    ) {
        self.agentID = agentID
        self.entryID = entryID
        self.name = name
        self.host = host
        self.status = status
        self.serverFingerprints = serverFingerprints
        self.identityFingerprints = identityFingerprints
        self.proof = proof
        self.issuedAt = issuedAt
        self.expiresAt = expiresAt
        self.identities = identities
        self.receipt = receipt
        self.statusToken = statusToken
    }
}

public struct Audit: Sendable, Hashable, Codable {
    public struct Event: Sendable, Hashable, Codable {
        public let type: String
        public let agentID: Agent.ID?
        public let entryID: Entry.ID?
        public let payload: Data?
        public let proof: Proof?
        public let timestamp: Date?

        public init(type: String, agentID: Agent.ID? = nil, entryID: Entry.ID? = nil, payload: Data? = nil, proof: Proof? = nil, timestamp: Date? = nil) {
            self.type = type
            self.agentID = agentID
            self.entryID = entryID
            self.payload = payload
            self.proof = proof
            self.timestamp = timestamp
        }
    }

    public let events: [Event]
    public let nextCursor: String?

    public init(events: [Event], nextCursor: String? = nil) {
        self.events = events
        self.nextCursor = nextCursor
    }
}
