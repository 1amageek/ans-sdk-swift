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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        self.kind = try container.decodeFirst(Kind.self, for: ["type", "kind"])
        self.name = try container.decodeFirst(String.self, for: ["name"])
        self.value = try container.decodeFirst(String.self, for: ["value", "data"])
        self.ttl = try container.decodeFirstIfPresent(Int.self, for: ["ttl"])
        self.priority = try container.decodeFirstIfPresent(Int.self, for: ["priority"])
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyCodingKey.self)
        try container.encode(kind, forKey: AnyCodingKey(stringValue: "type"))
        try container.encode(name, forKey: AnyCodingKey(stringValue: "name"))
        try container.encode(value, forKey: AnyCodingKey(stringValue: "value"))
        try container.encodeIfPresent(ttl, forKey: AnyCodingKey(stringValue: "ttl"))
        try container.encodeIfPresent(priority, forKey: AnyCodingKey(stringValue: "priority"))
    }
}
