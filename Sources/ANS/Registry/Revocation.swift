public enum RevocationReason: Sendable, Hashable, RawRepresentable, CustomStringConvertible {
    case keyCompromise
    case caCompromise
    case affiliationChanged
    case superseded
    case cessationOfOperation
    case privilegeWithdrawn
    case unspecified
    case other(String)

    public var rawValue: String {
        switch self {
        case .keyCompromise:
            return "KEY_COMPROMISE"
        case .caCompromise:
            return "CA_COMPROMISE"
        case .affiliationChanged:
            return "AFFILIATION_CHANGED"
        case .superseded:
            return "SUPERSEDED"
        case .cessationOfOperation:
            return "CESSATION_OF_OPERATION"
        case .privilegeWithdrawn:
            return "PRIVILEGE_WITHDRAWN"
        case .unspecified:
            return "UNSPECIFIED"
        case .other(let value):
            return value.uppercased()
        }
    }

    public var description: String {
        rawValue
    }

    public init(rawValue: String) {
        switch rawValue.uppercased() {
        case "KEY_COMPROMISE":
            self = .keyCompromise
        case "CA_COMPROMISE":
            self = .caCompromise
        case "AFFILIATION_CHANGED":
            self = .affiliationChanged
        case "SUPERSEDED":
            self = .superseded
        case "CESSATION_OF_OPERATION":
            self = .cessationOfOperation
        case "PRIVILEGE_WITHDRAWN":
            self = .privilegeWithdrawn
        case "UNSPECIFIED":
            self = .unspecified
        default:
            self = .other(rawValue)
        }
    }
}

public struct RevocationRequest: Sendable, Hashable {
    public let reason: RevocationReason
    public let comments: String?

    public init(reason: RevocationReason, comments: String? = nil) {
        self.reason = reason
        self.comments = comments
    }
}

public struct RevocationResponse: Sendable, Hashable {
    public let agentID: Agent.ID
    public let name: Name?
    public let status: Registration.Status
    public let revokedAt: String?
    public let reason: RevocationReason?
    public let dnsRecordsToRemove: [Registration.DNSRecord]
    public let links: [Registration.Link]
    public let message: String?

    public init(
        agentID: Agent.ID,
        name: Name? = nil,
        status: Registration.Status,
        revokedAt: String? = nil,
        reason: RevocationReason? = nil,
        dnsRecordsToRemove: [Registration.DNSRecord] = [],
        links: [Registration.Link] = [],
        message: String? = nil
    ) {
        self.agentID = agentID
        self.name = name
        self.status = status
        self.revokedAt = revokedAt
        self.reason = reason
        self.dnsRecordsToRemove = dnsRecordsToRemove
        self.links = links
        self.message = message
    }
}

#if !hasFeature(Embedded)
extension RevocationReason: Codable {}
extension RevocationRequest: Codable {}
extension RevocationResponse: Codable {}
#endif
