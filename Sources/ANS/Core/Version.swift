public struct Version: Sendable, Hashable, Comparable, CustomStringConvertible {
    public let major: Int
    public let minor: Int
    public let patch: Int

    public var rawValue: String {
        "\(major).\(minor).\(patch)"
    }

    public var description: String {
        rawValue
    }

    public init(major: Int, minor: Int, patch: Int) throws(ParsingError) {
        guard major >= 0, minor >= 0, patch >= 0 else {
            throw ParsingError.invalidVersion("\(major).\(minor).\(patch)")
        }

        self.major = major
        self.minor = minor
        self.patch = patch
    }

    public init(_ rawValue: String) throws(ParsingError) {
        let normalized: Substring
        if rawValue.first == "v" || rawValue.first == "V" {
            normalized = rawValue.dropFirst()
        } else {
            normalized = Substring(rawValue)
        }

        let parts = normalized.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else {
            throw ParsingError.invalidVersion(rawValue)
        }

        self.major = try Self.parse(parts[0], original: rawValue)
        self.minor = try Self.parse(parts[1], original: rawValue)
        self.patch = try Self.parse(parts[2], original: rawValue)
    }

    private static func parse(_ part: Substring, original: String) throws(ParsingError) -> Int {
        guard !part.isEmpty else {
            throw ParsingError.invalidVersion(original)
        }

        guard part.utf8.allSatisfy({ byte in byte >= 48 && byte <= 57 }) else {
            throw ParsingError.invalidVersion(original)
        }

        if part.count > 1, part.first == "0" {
            throw ParsingError.invalidVersion(original)
        }

        guard let value = Int(part) else {
            throw ParsingError.invalidVersion(original)
        }

        return value
    }
}

#if !hasFeature(Embedded)
extension Version: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        do {
            try self.init(rawValue)
        } catch let error {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "\(error)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
#endif

public extension Version {
    static func < (lhs: Version, rhs: Version) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        }
        return lhs.patch < rhs.patch
    }
}
