public enum Renewal {
    public struct Request: Sendable, Hashable {
        public let serverCSRPEM: String?
        public let serverCertificatePEM: String?
        public let serverCertificateChainPEM: String?

        public init(
            serverCSRPEM: String? = nil,
            serverCertificatePEM: String? = nil,
            serverCertificateChainPEM: String? = nil
        ) {
            self.serverCSRPEM = serverCSRPEM
            self.serverCertificatePEM = serverCertificatePEM
            self.serverCertificateChainPEM = serverCertificateChainPEM
        }
    }

    public struct Challenges: Sendable, Hashable {
        public let dns01: Registration.Challenge?
        public let http01: Registration.Challenge?

        public init(dns01: Registration.Challenge? = nil, http01: Registration.Challenge? = nil) {
            self.dns01 = dns01
            self.http01 = http01
        }
    }

    public struct Submission: Sendable, Hashable {
        public let type: WireValue
        public let status: Registration.Status
        public let csrID: String?
        public let challenges: Challenges?
        public let expiresAt: String
        public let nextStep: Registration.Step
        public let links: [Registration.Link]

        public init(
            type: WireValue,
            status: Registration.Status,
            csrID: String? = nil,
            challenges: Challenges? = nil,
            expiresAt: String,
            nextStep: Registration.Step,
            links: [Registration.Link] = []
        ) {
            self.type = type
            self.status = status
            self.csrID = csrID
            self.challenges = challenges
            self.expiresAt = expiresAt
            self.nextStep = nextStep
            self.links = links
        }
    }

    public struct Status: Sendable, Hashable {
        public let type: WireValue
        public let status: Registration.Status
        public let csrID: String?
        public let challenges: Challenges?
        public let tlsaDNSRecord: Registration.DNSRecord?
        public let failureReason: String?
        public let expiresAt: String
        public let nextStep: Registration.Step

        public init(
            type: WireValue,
            status: Registration.Status,
            csrID: String? = nil,
            challenges: Challenges? = nil,
            tlsaDNSRecord: Registration.DNSRecord? = nil,
            failureReason: String? = nil,
            expiresAt: String,
            nextStep: Registration.Step
        ) {
            self.type = type
            self.status = status
            self.csrID = csrID
            self.challenges = challenges
            self.tlsaDNSRecord = tlsaDNSRecord
            self.failureReason = failureReason
            self.expiresAt = expiresAt
            self.nextStep = nextStep
        }
    }

    public struct Verification: Sendable, Hashable {
        public let status: Registration.Status
        public let csrID: String?
        public let tlsaDNSRecord: Registration.DNSRecord?
        public let nextStep: Registration.Step

        public init(
            status: Registration.Status,
            csrID: String? = nil,
            tlsaDNSRecord: Registration.DNSRecord? = nil,
            nextStep: Registration.Step
        ) {
            self.status = status
            self.csrID = csrID
            self.tlsaDNSRecord = tlsaDNSRecord
            self.nextStep = nextStep
        }
    }
}

#if !hasFeature(Embedded)
extension Renewal.Request: Codable {
    private enum CodingKeys: String, CodingKey {
        case serverCSRPEM = "serverCsrPEM"
        case serverCertificatePEM
        case serverCertificateChainPEM
    }
}
extension Renewal.Challenges: Codable {}
extension Renewal.Submission: Codable {
    private enum CodingKeys: String, CodingKey {
        case type = "renewalType"
        case status
        case csrID = "csrId"
        case challenges
        case expiresAt
        case nextStep
        case links
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            type: try container.decode(WireValue.self, forKey: .type),
            status: try container.decode(Registration.Status.self, forKey: .status),
            csrID: try container.decodeIfPresent(String.self, forKey: .csrID),
            challenges: try container.decodeIfPresent(Renewal.Challenges.self, forKey: .challenges),
            expiresAt: try container.decode(String.self, forKey: .expiresAt),
            nextStep: try container.decode(Registration.Step.self, forKey: .nextStep),
            links: try container.decodeIfPresent([Registration.Link].self, forKey: .links) ?? []
        )
    }
}
extension Renewal.Status: Codable {
    private enum CodingKeys: String, CodingKey {
        case type = "renewalType"
        case status
        case csrID = "csrId"
        case challenges
        case tlsaDNSRecord = "tlsaDnsRecord"
        case failureReason
        case expiresAt
        case nextStep
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            type: try container.decode(WireValue.self, forKey: .type),
            status: try container.decode(Registration.Status.self, forKey: .status),
            csrID: try container.decodeIfPresent(String.self, forKey: .csrID),
            challenges: try container.decodeIfPresent(Renewal.Challenges.self, forKey: .challenges),
            tlsaDNSRecord: try container.decodeIfPresent(Registration.DNSRecord.self, forKey: .tlsaDNSRecord),
            failureReason: try container.decodeIfPresent(String.self, forKey: .failureReason),
            expiresAt: try container.decode(String.self, forKey: .expiresAt),
            nextStep: try container.decode(Registration.Step.self, forKey: .nextStep)
        )
    }
}
extension Renewal.Verification: Codable {
    private enum CodingKeys: String, CodingKey {
        case status
        case csrID = "csrId"
        case tlsaDNSRecord = "tlsaDnsRecord"
        case nextStep
    }
}
#endif
