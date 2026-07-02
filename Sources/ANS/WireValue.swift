import Foundation

public struct WireValue: Sendable, Hashable, Codable, ExpressibleByStringLiteral, CustomStringConvertible {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(value)
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

protocol CanonicalWireValue: Sendable, Hashable, Codable, CustomStringConvertible {
    var rawValue: String { get }
    init(_ rawValue: String)
}

extension CanonicalWireValue {
    public var description: String { rawValue }
}
