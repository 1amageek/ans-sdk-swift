import Foundation

public struct Name: Sendable, Hashable, Codable, CustomStringConvertible {
    public let rawValue: String
    public let version: Version
    public let host: Host

    public init(rawValue: String) throws {
        guard rawValue.hasPrefix("ans://") else {
            throw ParsingError("ANS name must use the ans scheme")
        }

        let suffix = String(rawValue.dropFirst("ans://".count))
        guard !suffix.contains("/"), !suffix.contains("?"), !suffix.contains("#") else {
            throw ParsingError("ANS name must not contain path, query, or fragment components")
        }

        let labels = suffix.split(separator: ".", omittingEmptySubsequences: false)
        guard labels.count >= 5 else {
            throw ParsingError("ANS name must contain version and host labels")
        }

        let majorLabel = labels[0]
        guard majorLabel.hasPrefix("v") else {
            throw ParsingError("ANS name version must start with v")
        }

        let major = majorLabel.dropFirst()
        let version = try Version("\(major).\(labels[1]).\(labels[2])")
        let host = try Host(rawValue: labels.dropFirst(3).joined(separator: "."))

        self.version = version
        self.host = host
        self.rawValue = "ans://v\(version.rawValue).\(host.rawValue)"
    }

    public init(version: Version, host: Host) {
        self.version = version
        self.host = host
        self.rawValue = "ans://v\(version.rawValue).\(host.rawValue)"
    }

    public var description: String { rawValue }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(rawValue: container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
