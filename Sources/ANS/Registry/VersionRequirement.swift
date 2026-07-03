public struct VersionRequirement: Sendable, Hashable, CustomStringConvertible {
    public enum Kind: Sendable, Hashable {
        case any
        case exact(Version)
        case compatibleWith(Version)
        case patchCompatibleWith(Version)
    }

    public let rawValue: String
    public let kind: Kind

    public var description: String {
        rawValue
    }

    public init(_ rawValue: String) throws(ParsingError) {
        if rawValue == "*" || rawValue.lowercased() == "latest" {
            self.rawValue = rawValue
            self.kind = .any
            return
        }
        if rawValue.hasPrefix("^") {
            let version = try Version(String(rawValue.dropFirst()))
            self.rawValue = rawValue
            self.kind = .compatibleWith(version)
            return
        }
        if rawValue.hasPrefix("~") {
            let version = try Version(String(rawValue.dropFirst()))
            self.rawValue = rawValue
            self.kind = .patchCompatibleWith(version)
            return
        }

        let version = try Version(rawValue)
        self.rawValue = version.rawValue
        self.kind = .exact(version)
    }

    public init(exact version: Version) {
        self.rawValue = version.rawValue
        self.kind = .exact(version)
    }

    public func matches(_ version: Version) -> Bool {
        switch kind {
        case .any:
            return true
        case .exact(let exact):
            return version == exact
        case .compatibleWith(let base):
            guard version >= base else {
                return false
            }
            if base.major > 0 {
                return version.major == base.major
            }
            if base.minor > 0 {
                return version.major == 0 && version.minor == base.minor
            }
            return version.major == 0 && version.minor == 0 && version.patch == base.patch
        case .patchCompatibleWith(let base):
            return version >= base && version.major == base.major && version.minor == base.minor
        }
    }
}

#if !hasFeature(Embedded)
extension VersionRequirement.Kind: Codable {}
extension VersionRequirement: Codable {}
#endif
