import Foundation

public struct Page: Sendable, Hashable, Codable {
    public let limit: Int?
    public let cursor: String?

    public init(limit: Int? = nil, cursor: String? = nil) {
        self.limit = limit
        self.cursor = cursor
    }
}

public struct Search: Sendable, Hashable, Codable {
    public struct Result: Sendable, Hashable, Codable {
        public let agents: [Agent]
        public let nextCursor: String?

        public init(agents: [Agent], nextCursor: String? = nil) {
            self.agents = agents
            self.nextCursor = nextCursor
        }
    }

    public let host: Host?
    public let displayName: String?
    public let protocolKind: Endpoint.ProtocolKind?
    public let transport: Endpoint.TransportKind?
    public let tags: [String]
    public let status: Registration.Status?
    public let page: Page?

    public init(
        host: Host? = nil,
        displayName: String? = nil,
        protocolKind: Endpoint.ProtocolKind? = nil,
        transport: Endpoint.TransportKind? = nil,
        tags: [String] = [],
        status: Registration.Status? = nil,
        page: Page? = nil
    ) {
        self.host = host
        self.displayName = displayName
        self.protocolKind = protocolKind
        self.transport = transport
        self.tags = tags
        self.status = status
        self.page = page
    }
}

public struct VersionRequirement: Sendable, Hashable, Codable, CustomStringConvertible {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public var description: String { rawValue }
}

public struct Resolution: Sendable, Hashable, Codable {
    public let agent: Agent
    public let endpoint: Endpoint?

    public init(agent: Agent, endpoint: Endpoint? = nil) {
        self.agent = agent
        self.endpoint = endpoint
    }
}

public struct Revocation: Sendable, Hashable, Codable {
    public struct Reason: CanonicalWireValue, ExpressibleByStringLiteral {
        public let rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: String) {
            self.init(value)
        }

        public static let keyCompromise = Self("KEY_COMPROMISE")
        public static let cessationOfOperation = Self("CESSATION_OF_OPERATION")
        public static let affiliationChanged = Self("AFFILIATION_CHANGED")
        public static let superseded = Self("SUPERSEDED")
        public static let certificateHold = Self("CERTIFICATE_HOLD")
        public static let privilegeWithdrawn = Self("PRIVILEGE_WITHDRAWN")
        public static let aaCompromise = Self("AA_COMPROMISE")
    }

    public let reason: Reason
    public let comments: String?

    public init(reason: Reason, comments: String? = nil) {
        self.reason = reason
        self.comments = comments
    }
}
