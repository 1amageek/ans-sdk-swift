import Foundation

public struct Version: Sendable, Hashable, Codable, Comparable, CustomStringConvertible {
    public let major: Int
    public let minor: Int
    public let patch: Int

    public init(major: Int, minor: Int, patch: Int) throws {
        guard major >= 0, minor >= 0, patch >= 0 else {
            throw ParsingError("Version components must be non-negative")
        }
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    public init(_ rawValue: String) throws {
        guard !rawValue.contains("-"), !rawValue.contains("+") else {
            throw ParsingError("ANS versions do not support prerelease or build metadata")
        }

        let parts = rawValue.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else {
            throw ParsingError("Version must have major, minor, and patch components")
        }

        let components = try parts.map { part in
            guard !part.isEmpty, part.allSatisfy(\.isNumber), let value = Int(part) else {
                throw ParsingError("Version components must be numeric")
            }
            return value
        }

        try self.init(major: components[0], minor: components[1], patch: components[2])
    }

    public var rawValue: String { description }

    public var description: String {
        "\(major).\(minor).\(patch)"
    }

    public static func < (lhs: Version, rhs: Version) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
