import Foundation

public struct Host: Sendable, Hashable, Codable, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) throws {
        let normalized = rawValue.lowercased()
        try Self.validate(normalized)
        self.rawValue = normalized
    }

    public init(_ rawValue: String) throws {
        try self.init(rawValue: rawValue)
    }

    public var description: String { rawValue }

    private static func validate(_ value: String) throws {
        guard !value.isEmpty else {
            throw ParsingError("Host must not be empty")
        }
        guard value.utf8.count <= 237 else {
            throw ParsingError("Host exceeds ANS length limit")
        }
        guard !value.hasSuffix(".") else {
            throw ParsingError("Host must not include a trailing dot")
        }
        guard value.contains(".") else {
            throw ParsingError("Host must be a fully qualified domain name")
        }
        guard !isIPv4(value), !value.contains(":") else {
            throw ParsingError("Host must not be an IP literal")
        }

        let labels = value.split(separator: ".", omittingEmptySubsequences: false)
        for label in labels {
            guard !label.isEmpty else {
                throw ParsingError("Host labels must not be empty")
            }
            guard label.utf8.count <= 63 else {
                throw ParsingError("Host label exceeds 63 octets")
            }
            guard label.first != "-", label.last != "-" else {
                throw ParsingError("Host labels must not start or end with a hyphen")
            }
            guard label.allSatisfy({ character in
                character.isASCII && (character.isLetter || character.isNumber || character == "-")
            }) else {
                throw ParsingError("Host labels must contain only letters, digits, or hyphens")
            }
        }
    }

    private static func isIPv4(_ value: String) -> Bool {
        let parts = value.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return false }
        for part in parts {
            guard !part.isEmpty, part.allSatisfy(\.isNumber), let octet = Int(part), (0...255).contains(octet) else {
                return false
            }
        }
        return true
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(rawValue: container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
