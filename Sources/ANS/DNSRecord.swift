import Foundation

public struct DNSRecord: Sendable, Hashable, Codable {
    public struct Kind: CanonicalWireValue, ExpressibleByStringLiteral {
        public let rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: String) {
            self.init(value)
        }

        public static let txt = Self("TXT")
        public static let tlsa = Self("TLSA")
        public static let svcb = Self("SVCB")
        public static let https = Self("HTTPS")
        public static let cname = Self("CNAME")
    }

    public let kind: Kind
    public let name: String
    public let value: String
    public let ttl: Int?
    public let priority: Int?

    public init(kind: Kind, name: String, value: String, ttl: Int? = nil, priority: Int? = nil) {
        self.kind = kind
        self.name = name
        self.value = value
        self.ttl = ttl
        self.priority = priority
    }
}
