public struct Badge: Sendable, Hashable {
    public struct Status: Sendable, Hashable, RawRepresentable, CustomStringConvertible {
        public let rawValue: String

        public var description: String {
            rawValue
        }

        public init(rawValue: String) {
            self.rawValue = rawValue.uppercased()
        }

        public static let active = Self(rawValue: "ACTIVE")
        public static let warning = Self(rawValue: "WARNING")
        public static let deprecated = Self(rawValue: "DEPRECATED")
        public static let expired = Self(rawValue: "EXPIRED")
        public static let revoked = Self(rawValue: "REVOKED")
        public static let verified = Self(rawValue: "VERIFIED")

        public var isAcceptableForStrictVerification: Bool {
            self == .active || self == .warning || self == .verified
        }

        public var allowsConnection: Bool {
            self == .active || self == .warning || self == .deprecated || self == .verified
        }

        public var shouldReject: Bool {
            !allowsConnection
        }
    }

    public let agentID: Agent.ID?
    public let name: Name?
    public let host: Host
    public let status: Status
    public let serverFingerprint: Fingerprint?
    public let identityFingerprint: Fingerprint?
    public let eventType: WireValue?
    public let schemaVersion: WireValue?

    public init(
        agentID: Agent.ID? = nil,
        name: Name? = nil,
        host: Host,
        status: Status,
        serverFingerprint: Fingerprint? = nil,
        identityFingerprint: Fingerprint? = nil,
        eventType: WireValue? = nil,
        schemaVersion: WireValue? = nil
    ) {
        self.agentID = agentID
        self.name = name
        self.host = host
        self.status = status
        self.serverFingerprint = serverFingerprint
        self.identityFingerprint = identityFingerprint
        self.eventType = eventType
        self.schemaVersion = schemaVersion
    }
}

#if !hasFeature(Embedded)
extension Badge.Status: Codable {}
extension Badge: Codable {
    private enum CodingKeys: String, CodingKey {
        case agentID = "agentId"
        case name
        case host
        case status
        case serverFingerprint
        case identityFingerprint
        case eventType
        case schemaVersion
        case payload
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let status = try container.decode(Status.self, forKey: .status)
        let schemaVersion = try container.decodeIfPresent(WireValue.self, forKey: .schemaVersion)

        if let payload = try container.decodeIfPresent(BadgePayloadDTO.self, forKey: .payload) {
            let event = payload.producer.event
            let name = try Name(rawValue: event.ansName)
            self.init(
                agentID: Agent.ID(rawValue: event.ansId),
                name: name,
                host: try Host(rawValue: event.agent.host),
                status: status,
                serverFingerprint: try event.attestations.serverCert?.fingerprintValue(),
                identityFingerprint: try event.attestations.identityCert?.fingerprintValue(),
                eventType: WireValue(event.eventType),
                schemaVersion: schemaVersion
            )
            return
        }

        self.init(
            agentID: try container.decodeIfPresent(Agent.ID.self, forKey: .agentID),
            name: try container.decodeIfPresent(Name.self, forKey: .name),
            host: try container.decode(Host.self, forKey: .host),
            status: status,
            serverFingerprint: try container.decodeIfPresent(Fingerprint.self, forKey: .serverFingerprint),
            identityFingerprint: try container.decodeIfPresent(Fingerprint.self, forKey: .identityFingerprint),
            eventType: try container.decodeIfPresent(WireValue.self, forKey: .eventType),
            schemaVersion: schemaVersion
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(agentID, forKey: .agentID)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encode(host, forKey: .host)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(serverFingerprint, forKey: .serverFingerprint)
        try container.encodeIfPresent(identityFingerprint, forKey: .identityFingerprint)
        try container.encodeIfPresent(eventType, forKey: .eventType)
        try container.encodeIfPresent(schemaVersion, forKey: .schemaVersion)
    }
}

private struct BadgePayloadDTO: Decodable {
    let producer: BadgeProducerDTO
}

private struct BadgeProducerDTO: Decodable {
    let event: BadgeEventDTO
}

private struct BadgeEventDTO: Decodable {
    let ansId: String
    let ansName: String
    let eventType: String
    let agent: BadgeAgentDTO
    let attestations: BadgeAttestationsDTO
}

private struct BadgeAgentDTO: Decodable {
    let host: String
    let name: String?
    let version: String?
}

private struct BadgeAttestationsDTO: Decodable {
    let identityCert: BadgeCertificateDTO?
    let serverCert: BadgeCertificateDTO?
}

private struct BadgeCertificateDTO: Decodable {
    let fingerprint: String

    func fingerprintValue() throws(ParsingError) -> Fingerprint {
        try Fingerprint(rawValue: fingerprint)
    }
}
#endif
