public struct Name: Sendable, Hashable, CustomStringConvertible {
    public let version: Version
    public let host: Host

    public init(version: Version, host: Host) {
        self.version = version
        self.host = host
    }

    public init(rawValue: String) throws {
        let prefix = "ans://v"
        guard rawValue.hasPrefix(prefix) else {
            throw ParsingError("ANS name must start with ans://v")
        }

        let payload = rawValue.dropFirst(prefix.count)
        let parts = payload.split(separator: ".", maxSplits: 3, omittingEmptySubsequences: false)
        guard parts.count == 4 else {
            throw ParsingError("ANS name must include a semantic version and host")
        }

        let versionText = "\(parts[0]).\(parts[1]).\(parts[2])"
        let hostText = String(parts[3])

        self.version = try Version(versionText)
        self.host = try Host(rawValue: hostText)
    }

    public var rawValue: String { description }

    public var description: String {
        "ans://v\(version.rawValue).\(host.rawValue)"
    }
}
