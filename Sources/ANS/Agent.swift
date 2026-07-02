import Foundation

public struct Entry: Sendable, Hashable, Codable {
    public struct ID: Sendable, Hashable, Codable, CustomStringConvertible {
        public let rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        public var description: String { rawValue }
    }
}

public struct Identity: Sendable, Hashable, Codable, Identifiable {
    public struct ID: Sendable, Hashable, Codable, CustomStringConvertible {
        public let rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        public var description: String { rawValue }
    }

    public struct Status: CanonicalWireValue {
        public let rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        public static let pendingControl = Self("PENDING_CONTROL")
        public static let verified = Self("VERIFIED")
        public static let revoked = Self("REVOKED")
    }

    public let id: ID
    public let status: Status

    public init(id: ID, status: Status) {
        self.id = id
        self.status = status
    }
}

public struct Agent: Sendable, Hashable, Codable, Identifiable {
    public struct ID: Sendable, Hashable, Codable, CustomStringConvertible {
        public let rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        public var description: String { rawValue }
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

    public init(
        id: ID,
        entryID: Entry.ID? = nil,
        name: Name? = nil,
        host: Host,
        displayName: String,
        description: String? = nil,
        version: Version? = nil,
        status: Registration.Status,
        endpoints: [Endpoint] = []
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
    }
}
