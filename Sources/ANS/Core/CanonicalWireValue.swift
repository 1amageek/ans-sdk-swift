import Foundation

public protocol CanonicalWireValue: Sendable, Hashable, Codable, CustomStringConvertible {
    var rawValue: String { get }
    init(_ rawValue: String)
}

extension CanonicalWireValue {
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
