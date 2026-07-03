public struct BadgeRecord: Sendable, Hashable {
    public let formatVersion: WireValue
    public let version: Version?
    public let url: URI
    public let source: BadgeRecordSource?

    public init(formatVersion: WireValue, version: Version? = nil, url: URI, source: BadgeRecordSource? = nil) {
        self.formatVersion = formatVersion
        self.version = version
        self.url = url
        self.source = source
    }

    public init(txt: String, source: BadgeRecordSource? = nil) throws(ParsingError) {
        guard !txt.isEmpty else {
            throw .invalidBadgeRecord(txt)
        }

        var formatVersion: WireValue?
        var version: Version?
        var url: URI?

        for rawPart in txt.split(separator: ";", omittingEmptySubsequences: false) {
            let part = rawPart.trimmingASCIIWhitespace()
            if let value = part.strippingPrefix("v=") {
                formatVersion = WireValue(value)
            } else if let value = part.strippingPrefix("version=") {
                version = try Version(value)
            } else if let value = part.strippingPrefix("url=") {
                let parsed = try URI(rawValue: value)
                guard parsed.scheme == "https" else {
                    throw .invalidURI(value)
                }
                url = parsed
            }
        }

        guard let formatVersion else {
            throw .missingField("v")
        }
        guard formatVersion == .ansBadge1 || formatVersion == .raBadge1 else {
            throw .invalidBadgeRecord(txt)
        }
        guard let url else {
            throw .missingField("url")
        }

        self.formatVersion = formatVersion
        self.version = version
        self.url = url
        self.source = source
    }
}

#if !hasFeature(Embedded)
extension BadgeRecord: Codable {}
#endif

public extension WireValue {
    static let ansBadge1 = WireValue("ans-badge1")
    static let raBadge1 = WireValue("ra-badge1")
}

private extension Substring {
    func trimmingASCIIWhitespace() -> String {
        var start = startIndex
        var end = endIndex

        while start < end, self[start].isASCIIWhitespace {
            start = index(after: start)
        }
        while start < end {
            let beforeEnd = index(before: end)
            guard self[beforeEnd].isASCIIWhitespace else {
                break
            }
            end = beforeEnd
        }
        return String(self[start..<end])
    }
}

private extension String {
    func strippingPrefix(_ prefix: String) -> String? {
        guard hasPrefix(prefix) else {
            return nil
        }
        return String(dropFirst(prefix.count))
    }
}

private extension Character {
    var isASCIIWhitespace: Bool {
        self == " " || self == "\t" || self == "\n" || self == "\r"
    }
}
