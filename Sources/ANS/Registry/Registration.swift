import Foundation

public enum Registration {
    public struct Status: CanonicalWireValue, ExpressibleByStringLiteral {
        public let rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: String) {
            self.init(value)
        }

        public static let pendingValidation = Self("PENDING_VALIDATION")
        public static let pendingCertificates = Self("PENDING_CERTS")
        public static let pendingDNS = Self("PENDING_DNS")
        public static let active = Self("ACTIVE")
        public static let deprecated = Self("DEPRECATED")
        public static let revoked = Self("REVOKED")
        public static let expired = Self("EXPIRED")
        public static let failed = Self("FAILED")

        public var isTerminal: Bool {
            self == .revoked || self == .expired
        }
    }

    public struct DiscoveryProfile: CanonicalWireValue, ExpressibleByStringLiteral {
        public let rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: String) {
            self.init(value)
        }

        public static let dnsAID = Self("ANS_DNSAID")
        public static let txt = Self("ANS_TXT")
        public static let svcb = Self("ANS_SVCB")
    }

    public struct Request: Sendable, Hashable, Codable {
        public let displayName: String
        public let host: Host
        public let endpoints: [Endpoint]
        public let version: Version?
        public let identityCSR: String?
        public let serverCSR: String?
        public let serverCertificate: String?
        public let description: String?
        public let discoveryProfiles: [DiscoveryProfile]

        public init(
            displayName: String,
            host: Host,
            endpoints: [Endpoint],
            version: Version? = nil,
            identityCSR: String? = nil,
            serverCSR: String? = nil,
            serverCertificate: String? = nil,
            description: String? = nil,
            discoveryProfiles: [DiscoveryProfile] = []
        ) throws {
            self.displayName = displayName
            self.host = host
            self.endpoints = endpoints
            self.version = version
            self.identityCSR = identityCSR
            self.serverCSR = serverCSR
            self.serverCertificate = serverCertificate
            self.description = description
            self.discoveryProfiles = discoveryProfiles
            try validate()
        }

        public func validate() throws {
            guard !displayName.isEmpty, displayName.count <= 64 else {
                throw ValidationError("Display name must be 1...64 characters")
            }
            if let description {
                guard description.count <= 150 else {
                    throw ValidationError("Description must be 150 characters or fewer")
                }
            }
            guard !endpoints.isEmpty else {
                throw ValidationError("Registration requires at least one endpoint")
            }
            guard (version == nil) == (identityCSR == nil) else {
                throw ValidationError("Version and identity CSR must be jointly present or absent")
            }
            for endpoint in endpoints {
                guard endpoint.url.host?.lowercased() == host.rawValue else {
                    throw ValidationError("Endpoint authority must match the agent host")
                }
            }
        }

        private enum CodingKeys: String, CodingKey {
            case displayName = "agentDisplayName"
            case host = "agentHost"
            case endpoints
            case version
            case identityCSR = "identityCsrPEM"
            case serverCSR = "serverCsrPEM"
            case serverCertificate = "serverCertificatePEM"
            case description = "agentDescription"
            case discoveryProfiles
        }
    }

    public struct Challenge: Sendable, Hashable, Codable {
        public let type: String
        public let dnsRecord: String?
        public let httpURL: URL?
        public let token: String
        public let expiresAt: Date?

        public init(type: String, dnsRecord: String? = nil, httpURL: URL? = nil, token: String, expiresAt: Date? = nil) {
            self.type = type
            self.dnsRecord = dnsRecord
            self.httpURL = httpURL
            self.token = token
            self.expiresAt = expiresAt
        }
    }

    public struct Step: Sendable, Hashable, Codable {
        public let action: String
        public let description: String

        public init(action: String, description: String) {
            self.action = action
            self.description = description
        }
    }

    public struct Pending: Sendable, Hashable, Codable {
        public let agentID: Agent.ID?
        public let name: Name?
        public let status: Status
        public let challenges: [Challenge]
        public let dnsRecords: [DNSRecord]
        public let nextSteps: [Step]

        public init(
            agentID: Agent.ID?,
            name: Name?,
            status: Status,
            challenges: [Challenge] = [],
            dnsRecords: [DNSRecord] = [],
            nextSteps: [Step] = []
        ) {
            self.agentID = agentID
            self.name = name
            self.status = status
            self.challenges = challenges
            self.dnsRecords = dnsRecords
            self.nextSteps = nextSteps
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: AnyCodingKey.self)
            self.agentID = try container.decodeFirstIfPresent(Agent.ID.self, for: ["agentId", "agentID"])
            self.name = try container.decodeFirstIfPresent(Name.self, for: ["ansName", "name"])
            self.status = try container.decodeFirst(Status.self, for: ["status", "agentStatus"])
            self.challenges = try container.decodeFirstIfPresent([Challenge].self, for: ["challenges"]) ?? []
            self.dnsRecords = try container.decodeFirstIfPresent([DNSRecord].self, for: ["dnsRecords"]) ?? []
            self.nextSteps = try container.decodeFirstIfPresent([Step].self, for: ["nextSteps"]) ?? []
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: AnyCodingKey.self)
            try container.encodeIfPresent(agentID, forKey: AnyCodingKey(stringValue: "agentId"))
            try container.encodeIfPresent(name, forKey: AnyCodingKey(stringValue: "ansName"))
            try container.encode(status, forKey: AnyCodingKey(stringValue: "status"))
            try container.encode(challenges, forKey: AnyCodingKey(stringValue: "challenges"))
            try container.encode(dnsRecords, forKey: AnyCodingKey(stringValue: "dnsRecords"))
            try container.encode(nextSteps, forKey: AnyCodingKey(stringValue: "nextSteps"))
        }
    }
}
