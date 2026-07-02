import Foundation

public struct Identity: Sendable, Hashable, Codable, Identifiable {
    public struct ID: Sendable, Hashable, Codable, CustomStringConvertible {
        public let rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        public var description: String { rawValue }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            self.init(try container.decode(String.self))
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
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
