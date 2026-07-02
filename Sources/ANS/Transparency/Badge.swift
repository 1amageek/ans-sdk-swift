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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        self.agentID = try container.decodeFirstIfPresent(Agent.ID.self, for: ["agentId", "agentID"])
        self.entryID = try container.decodeFirstIfPresent(Entry.ID.self, for: ["ansId", "entryId", "entryID"])
        self.name = try container.decodeFirstIfPresent(Name.self, for: ["ansName", "name"])
        self.host = try container.decodeFirst(Host.self, for: ["agentHost", "host"])
        self.status = try container.decodeFirst(Status.self, for: ["status", "badgeStatus"])
        self.serverFingerprints = try container.decodeFirstIfPresent([Fingerprint].self, for: ["serverCertificateFingerprints", "serverFingerprints", "serverCertFingerprints"]) ?? []
        self.identityFingerprints = try container.decodeFirstIfPresent([Fingerprint].self, for: ["identityCertificateFingerprints", "identityFingerprints", "identityCertFingerprints"]) ?? []
        self.proof = try container.decodeFirstIfPresent(Proof.self, for: ["merkleProof", "proof"])
        self.issuedAt = try container.decodeFirstIfPresent(Date.self, for: ["issuedAt"])
        self.expiresAt = try container.decodeFirstIfPresent(Date.self, for: ["expiresAt"])
        self.identities = try container.decodeFirstIfPresent([Identity].self, for: ["identities"]) ?? []
        self.receipt = try container.decodeFirstIfPresent(Receipt.self, for: ["receipt", "transparencyReceipt"])
        self.statusToken = try container.decodeFirstIfPresent(Token.self, for: ["statusToken"])
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyCodingKey.self)
        try container.encodeIfPresent(agentID, forKey: AnyCodingKey(stringValue: "agentId"))
        try container.encodeIfPresent(entryID, forKey: AnyCodingKey(stringValue: "ansId"))
        try container.encodeIfPresent(name, forKey: AnyCodingKey(stringValue: "ansName"))
        try container.encode(host, forKey: AnyCodingKey(stringValue: "agentHost"))
        try container.encode(status, forKey: AnyCodingKey(stringValue: "status"))
        try container.encode(serverFingerprints, forKey: AnyCodingKey(stringValue: "serverCertificateFingerprints"))
        try container.encode(identityFingerprints, forKey: AnyCodingKey(stringValue: "identityCertificateFingerprints"))
        try container.encodeIfPresent(proof, forKey: AnyCodingKey(stringValue: "merkleProof"))
        try container.encodeIfPresent(issuedAt, forKey: AnyCodingKey(stringValue: "issuedAt"))
        try container.encodeIfPresent(expiresAt, forKey: AnyCodingKey(stringValue: "expiresAt"))
        try container.encode(identities, forKey: AnyCodingKey(stringValue: "identities"))
        try container.encodeIfPresent(receipt, forKey: AnyCodingKey(stringValue: "receipt"))
        try container.encodeIfPresent(statusToken, forKey: AnyCodingKey(stringValue: "statusToken"))
    }
}
