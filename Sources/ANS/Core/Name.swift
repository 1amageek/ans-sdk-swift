public struct Name: Sendable, Hashable, CustomStringConvertible {
    public let rawValue: String
    public let version: Version
    public let host: Host

    public var description: String {
        rawValue
    }

    public init(rawValue: String) throws(ParsingError) {
        let prefix = "ans://"
        guard rawValue.hasPrefix(prefix) else {
            throw ParsingError.invalidScheme(expected: "ans")
        }

        let body = rawValue.dropFirst(prefix.count)
        guard body.first == "v" else {
            throw ParsingError.invalidName(rawValue)
        }

        let parts = body.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count >= 5 else {
            throw ParsingError.invalidName(rawValue)
        }

        let majorPart = parts[0].dropFirst()
        let versionRawValue = "\(majorPart).\(parts[1]).\(parts[2])"
        let hostRawValue = parts.dropFirst(3).joined(separator: ".")

        self.version = try Version(versionRawValue)
        self.host = try Host(rawValue: hostRawValue)
        self.rawValue = "ans://v\(version.rawValue).\(host.rawValue)"
    }

    public init(version: Version, host: Host) {
        self.version = version
        self.host = host
        self.rawValue = "ans://v\(version.rawValue).\(host.rawValue)"
    }

}

#if !hasFeature(Embedded)
extension Name: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        do {
            try self.init(rawValue: rawValue)
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
