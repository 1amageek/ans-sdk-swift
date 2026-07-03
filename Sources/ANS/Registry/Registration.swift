public enum Registration {
    public struct Status: Sendable, Hashable, RawRepresentable, CustomStringConvertible {
        public let rawValue: String

        public var description: String {
            rawValue
        }

        public init(rawValue: String) {
            self.rawValue = rawValue.uppercased()
        }

        public static let pendingValidation = Self(rawValue: "PENDING_VALIDATION")
        public static let pendingCertificates = Self(rawValue: "PENDING_CERTS")
        public static let pendingDNS = Self(rawValue: "PENDING_DNS")
        public static let active = Self(rawValue: "ACTIVE")
        public static let deprecated = Self(rawValue: "DEPRECATED")
        public static let revoked = Self(rawValue: "REVOKED")
        public static let expired = Self(rawValue: "EXPIRED")
        public static let failed = Self(rawValue: "FAILED")
    }

    public struct Request: Sendable, Hashable {
        public let displayName: String
        public let host: Host
        public let endpoints: [Endpoint]
        public let version: Version
        public let identityCSRPEM: String?
        public let serverCSRPEM: String?
        public let serverCertificatePEM: String?
        public let serverCertificateChainPEM: String?
        public let description: String?
        public let discoveryProfiles: [WireValue]

        public init(
            displayName: String,
            host: Host,
            endpoints: [Endpoint],
            version: Version,
            identityCSRPEM: String? = nil,
            serverCSRPEM: String? = nil,
            serverCertificatePEM: String? = nil,
            serverCertificateChainPEM: String? = nil,
            description: String? = nil,
            discoveryProfiles: [WireValue] = []
        ) throws(ValidationError) {
            guard !displayName.isEmpty, displayName.count <= 64 else {
                throw ValidationError.invalidDisplayName
            }

            if let description {
                guard description.count <= 150 else {
                    throw ValidationError.invalidDescription
                }
            }

            guard !endpoints.isEmpty else {
                throw ValidationError.emptyEndpoints
            }

            for endpoint in endpoints {
                guard endpoint.url.host == host else {
                    throw ValidationError.endpointHostMismatch(expected: host, actual: endpoint.url.host)
                }
            }

            self.displayName = displayName
            self.host = host
            self.endpoints = endpoints
            self.version = version
            self.identityCSRPEM = identityCSRPEM
            self.serverCSRPEM = serverCSRPEM
            self.serverCertificatePEM = serverCertificatePEM
            self.serverCertificateChainPEM = serverCertificateChainPEM
            self.description = description
            self.discoveryProfiles = discoveryProfiles
        }
    }

    public struct Pending: Sendable, Hashable {
        public let agent: Agent
        public let status: Status?
        public let expiresAt: String?
        public let challenges: [Challenge]
        public let dnsRecords: [DNSRecord]
        public let links: [Link]
        public let steps: [Step]

        public init(
            agent: Agent,
            status: Status? = nil,
            expiresAt: String? = nil,
            challenges: [Challenge] = [],
            dnsRecords: [DNSRecord] = [],
            links: [Link] = [],
            steps: [Step] = []
        ) {
            self.agent = agent
            self.status = status
            self.expiresAt = expiresAt
            self.challenges = challenges
            self.dnsRecords = dnsRecords
            self.links = links
            self.steps = steps
        }
    }

    public struct Step: Sendable, Hashable {
        public let kind: WireValue
        public let message: String

        public init(kind: WireValue, message: String) {
            self.kind = kind
            self.message = message
        }
    }

    public struct Challenge: Sendable, Hashable {
        public let type: WireValue
        public let token: String?
        public let keyAuthorization: String?
        public let httpPath: String?
        public let dnsRecord: DNSRecord?
        public let expiresAt: String?

        public init(
            type: WireValue,
            token: String? = nil,
            keyAuthorization: String? = nil,
            httpPath: String? = nil,
            dnsRecord: DNSRecord? = nil,
            expiresAt: String? = nil
        ) {
            self.type = type
            self.token = token
            self.keyAuthorization = keyAuthorization
            self.httpPath = httpPath
            self.dnsRecord = dnsRecord
            self.expiresAt = expiresAt
        }
    }

    public struct DNSRecord: Sendable, Hashable {
        public let name: String
        public let type: WireValue
        public let value: String
        public let purpose: WireValue?
        public let ttl: Int?
        public let priority: Int?
        public let required: Bool

        public init(
            name: String,
            type: WireValue,
            value: String,
            purpose: WireValue? = nil,
            ttl: Int? = nil,
            priority: Int? = nil,
            required: Bool = false
        ) {
            self.name = name
            self.type = type
            self.value = value
            self.purpose = purpose
            self.ttl = ttl
            self.priority = priority
            self.required = required
        }
    }

    public struct Link: Sendable, Hashable {
        public let href: String
        public let rel: String

        public init(href: String, rel: String) {
            self.href = href
            self.rel = rel
        }
    }
}

#if !hasFeature(Embedded)
extension Registration.Status: Codable {}
extension Registration.Request: Codable {}
extension Registration.Pending: Codable {}
extension Registration.Step: Codable {}
extension Registration.Challenge: Codable {}
extension Registration.DNSRecord: Codable {}
extension Registration.Link: Codable {}
#endif
