public struct Identity: Sendable, Hashable, Identifiable {
    public struct ID: Sendable, Hashable, RawRepresentable, CustomStringConvertible {
        public let rawValue: String

        public var description: String {
            rawValue
        }

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public struct Status: Sendable, Hashable, RawRepresentable, CustomStringConvertible {
        public let rawValue: String

        public var description: String {
            rawValue
        }

        public init(rawValue: String) {
            self.rawValue = rawValue.uppercased()
        }

        public static let pendingControl = Self(rawValue: "PENDING_CONTROL")
        public static let verified = Self(rawValue: "VERIFIED")
        public static let revoked = Self(rawValue: "REVOKED")
        public static let expired = Self(rawValue: "EXPIRED")
    }

    public struct ChallengeRound: Sendable, Hashable {
        public let id: ID
        public let kind: WireValue
        public let value: String
        public let status: Status
        public let nonce: String
        public let expiresAt: String
        public let challenges: [ProofChallenge]

        public init(
            id: ID,
            kind: WireValue,
            value: String,
            status: Status,
            nonce: String,
            expiresAt: String,
            challenges: [ProofChallenge]
        ) {
            self.id = id
            self.kind = kind
            self.value = value
            self.status = status
            self.nonce = nonce
            self.expiresAt = expiresAt
            self.challenges = challenges
        }
    }

    public struct ProofChallenge: Sendable, Hashable {
        public let keyID: String?
        public let signingInput: String

        public init(keyID: String? = nil, signingInput: String) {
            self.keyID = keyID
            self.signingInput = signingInput
        }
    }

    public struct Details: Sendable, Hashable, Identifiable {
        public let id: ID
        public let kind: WireValue
        public let value: String
        public let status: Status
        public let proofMethod: WireValue?
        public let pendingValue: String?
        public let verifiedAt: String?
        public let createdAt: String
        public let linkedAgents: [LinkedAgent]

        public init(
            id: ID,
            kind: WireValue,
            value: String,
            status: Status,
            proofMethod: WireValue? = nil,
            pendingValue: String? = nil,
            verifiedAt: String? = nil,
            createdAt: String,
            linkedAgents: [LinkedAgent] = []
        ) {
            self.id = id
            self.kind = kind
            self.value = value
            self.status = status
            self.proofMethod = proofMethod
            self.pendingValue = pendingValue
            self.verifiedAt = verifiedAt
            self.createdAt = createdAt
            self.linkedAgents = linkedAgents
        }
    }

    public struct LinkedAgent: Sendable, Hashable {
        public let agentID: Agent.ID
        public let linkedAt: String?
        public let status: Registration.Status?

        public init(agentID: Agent.ID, linkedAt: String? = nil, status: Registration.Status? = nil) {
            self.agentID = agentID
            self.linkedAt = linkedAt
            self.status = status
        }
    }

    public struct LinkedIdentity: Sendable, Hashable {
        public let id: ID
        public let kind: WireValue
        public let value: String
        public let status: Status
        public let linkedAt: String?
        public let linkLogID: String?
        public let keysLogID: String?
        public let keys: [JSONValue]

        public init(
            id: ID,
            kind: WireValue,
            value: String,
            status: Status,
            linkedAt: String? = nil,
            linkLogID: String? = nil,
            keysLogID: String? = nil,
            keys: [JSONValue] = []
        ) {
            self.id = id
            self.kind = kind
            self.value = value
            self.status = status
            self.linkedAt = linkedAt
            self.linkLogID = linkLogID
            self.keysLogID = keysLogID
            self.keys = keys
        }
    }

    public struct Page: Sendable, Hashable {
        public let items: [Details]
        public let returnedCount: Int
        public let limit: Int
        public let nextCursor: String?
        public let hasMore: Bool

        public init(items: [Details], returnedCount: Int, limit: Int, nextCursor: String? = nil, hasMore: Bool) {
            self.items = items
            self.returnedCount = returnedCount
            self.limit = limit
            self.nextCursor = nextCursor
            self.hasMore = hasMore
        }
    }

    public struct LinkedAgentPage: Sendable, Hashable {
        public let agents: [LinkedAgent]
        public let total: Int

        public init(agents: [LinkedAgent], total: Int) {
            self.agents = agents
            self.total = total
        }
    }

    public struct LinkedIdentityPage: Sendable, Hashable {
        public let identities: [LinkedIdentity]
        public let total: Int

        public init(identities: [LinkedIdentity], total: Int) {
            self.identities = identities
            self.total = total
        }
    }

    public struct LinkResult: Sendable, Hashable {
        public let linked: Int

        public init(linked: Int) {
            self.linked = linked
        }
    }

    public let id: ID
    public let status: Status

    public init(id: ID, status: Status) {
        self.id = id
        self.status = status
    }
}

#if !hasFeature(Embedded)
extension Identity.ID: Codable {}
extension Identity.Status: Codable {}
extension Identity: Codable {}
extension Identity.ChallengeRound: Codable {
    private enum CodingKeys: String, CodingKey {
        case id = "identityId"
        case kind
        case value
        case status
        case nonce
        case expiresAt
        case challenges
    }
}
extension Identity.ProofChallenge: Codable {
    private enum CodingKeys: String, CodingKey {
        case keyID = "kid"
        case signingInput
    }
}
extension Identity.Details: Codable {
    private enum CodingKeys: String, CodingKey {
        case id = "identityId"
        case kind
        case value
        case status
        case proofMethod
        case pendingValue
        case verifiedAt
        case createdAt
        case linkedAgents
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(Identity.ID.self, forKey: .id),
            kind: try container.decode(WireValue.self, forKey: .kind),
            value: try container.decode(String.self, forKey: .value),
            status: try container.decode(Identity.Status.self, forKey: .status),
            proofMethod: try container.decodeIfPresent(WireValue.self, forKey: .proofMethod),
            pendingValue: try container.decodeIfPresent(String.self, forKey: .pendingValue),
            verifiedAt: try container.decodeIfPresent(String.self, forKey: .verifiedAt),
            createdAt: try container.decode(String.self, forKey: .createdAt),
            linkedAgents: try container.decodeIfPresent([Identity.LinkedAgent].self, forKey: .linkedAgents) ?? []
        )
    }
}
extension Identity.LinkedAgent: Codable {
    private enum CodingKeys: String, CodingKey {
        case agentID = "agentId"
        case ansID = "ansId"
        case linkedAt
        case status = "agentStatus"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let agentID = try container.decodeIfPresent(Agent.ID.self, forKey: .agentID)
            ?? container.decode(Agent.ID.self, forKey: .ansID)
        self.init(
            agentID: agentID,
            linkedAt: try container.decodeIfPresent(String.self, forKey: .linkedAt),
            status: try container.decodeIfPresent(Registration.Status.self, forKey: .status)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(agentID, forKey: .agentID)
        try container.encodeIfPresent(linkedAt, forKey: .linkedAt)
        try container.encodeIfPresent(status, forKey: .status)
    }
}
extension Identity.LinkedIdentity: Codable {
    private enum CodingKeys: String, CodingKey {
        case id = "identityId"
        case kind
        case value
        case status = "identityStatus"
        case linkedAt
        case linkLogID = "linkLogId"
        case keysLogID = "keysLogId"
        case keys
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(Identity.ID.self, forKey: .id),
            kind: try container.decode(WireValue.self, forKey: .kind),
            value: try container.decode(String.self, forKey: .value),
            status: try container.decode(Identity.Status.self, forKey: .status),
            linkedAt: try container.decodeIfPresent(String.self, forKey: .linkedAt),
            linkLogID: try container.decodeIfPresent(String.self, forKey: .linkLogID),
            keysLogID: try container.decodeIfPresent(String.self, forKey: .keysLogID),
            keys: try container.decodeIfPresent([JSONValue].self, forKey: .keys) ?? []
        )
    }
}
extension Identity.Page: Codable {}
extension Identity.LinkedAgentPage: Codable {}
extension Identity.LinkedIdentityPage: Codable {}
extension Identity.LinkResult: Codable {}
#endif
