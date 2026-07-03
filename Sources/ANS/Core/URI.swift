public struct URI: Sendable, Hashable, CustomStringConvertible {
    public let rawValue: String
    public let scheme: String
    public let host: Host
    public let port: Int?
    public let path: String

    public var description: String {
        rawValue
    }

    public init(rawValue: String) throws(ParsingError) {
        guard let colon = rawValue.firstIndex(of: ":") else {
            throw ParsingError.invalidURI(rawValue)
        }

        let firstSlash = rawValue.index(after: colon)
        guard firstSlash < rawValue.endIndex, rawValue[firstSlash] == "/" else {
            throw ParsingError.invalidURI(rawValue)
        }

        let secondSlash = rawValue.index(after: firstSlash)
        guard secondSlash < rawValue.endIndex, rawValue[secondSlash] == "/" else {
            throw ParsingError.invalidURI(rawValue)
        }

        let scheme = rawValue[..<colon].lowercased()
        guard !scheme.isEmpty, scheme.utf8.allSatisfy(Self.isSchemeByte) else {
            throw ParsingError.invalidURI(rawValue)
        }

        let authorityStart = rawValue.index(after: secondSlash)
        let authorityEnd = rawValue[authorityStart...].firstIndex { character in
            character == "/" || character == "?" || character == "#"
        } ?? rawValue.endIndex
        let pathEnd = rawValue[authorityEnd...].firstIndex { character in
            character == "?" || character == "#"
        } ?? rawValue.endIndex
        let path = authorityEnd < pathEnd ? String(rawValue[authorityEnd..<pathEnd]) : ""

        let authority = rawValue[authorityStart..<authorityEnd]
        guard !authority.isEmpty, !authority.contains("@") else {
            throw ParsingError.invalidURI(rawValue)
        }

        let parsedAuthority = try Self.parseAuthority(String(authority), original: rawValue)
        self.rawValue = rawValue
        self.scheme = scheme
        self.host = parsedAuthority.host
        self.port = parsedAuthority.port
        self.path = path
    }

    public init(scheme: String, host: Host, port: Int? = nil, path: String = "") throws(ParsingError) {
        guard !scheme.isEmpty, scheme.utf8.allSatisfy(Self.isSchemeByte) else {
            throw ParsingError.invalidURI(scheme)
        }
        if let port {
            guard port > 0, port <= 65_535 else {
                throw ParsingError.invalidURI("\(host.rawValue):\(port)")
            }
        }
        guard path.isEmpty || path.hasPrefix("/") else {
            throw ParsingError.invalidURI(path)
        }

        self.scheme = scheme.lowercased()
        self.host = host
        self.port = port
        self.path = path
        self.rawValue = "\(self.scheme)://\(host.rawValue)\(port.map { ":\($0)" } ?? "")\(path)"
    }

}

public extension URI {
    func appending(path: String, queryItems: [(String, String?)] = []) throws(ParsingError) -> URI {
        guard path.isEmpty || path.hasPrefix("/") else {
            throw ParsingError.invalidURI(path)
        }

        let basePath = self.path.trimmingSuffix("/")
        let appendedPath = path.isEmpty ? "" : path
        var value = "\(scheme)://\(host.rawValue)\(port.map { ":\($0)" } ?? "")\(basePath)\(appendedPath)"
        let query = queryItems.compactMap { item -> String? in
            guard let value = item.1 else {
                return nil
            }
            return "\(Self.percentEncode(item.0))=\(Self.percentEncode(value))"
        }
        if !query.isEmpty {
            value += "?\(query.joined(separator: "&"))"
        }
        return try URI(rawValue: value)
    }

    static func percentEncode(_ value: String) -> String {
        let allowed = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~".utf8)
        var output: [UInt8] = []
        for byte in value.utf8 {
            if allowed.contains(byte) {
                output.append(byte)
            } else {
                let hex = Array(String(formatByte: byte).utf8)
                output.append(37)
                output.append(contentsOf: hex)
            }
        }
        return String(decoding: output, as: UTF8.self)
    }
}

private extension String {
    init(formatByte byte: UInt8) {
        let table = Array("0123456789ABCDEF".utf8)
        self = String(decoding: [table[Int(byte >> 4)], table[Int(byte & 0x0F)]], as: UTF8.self)
    }

    func trimmingSuffix(_ suffix: String) -> String {
        guard hasSuffix(suffix) else {
            return self
        }
        return String(dropLast(suffix.count))
    }
}

#if !hasFeature(Embedded)
extension URI: Codable {
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

extension URI {
    private static func parseAuthority(_ authority: String, original: String) throws(ParsingError) -> (host: Host, port: Int?) {
        let parts = authority.split(separator: ":", omittingEmptySubsequences: false)
        switch parts.count {
        case 1:
            return (try Host(rawValue: String(parts[0])), nil)
        case 2:
            guard !parts[1].isEmpty, parts[1].utf8.allSatisfy({ byte in byte >= 48 && byte <= 57 }) else {
                throw ParsingError.invalidURI(original)
            }
            guard let port = Int(parts[1]), port > 0, port <= 65_535 else {
                throw ParsingError.invalidURI(original)
            }
            return (try Host(rawValue: String(parts[0])), port)
        default:
            throw ParsingError.invalidURI(original)
        }
    }

    private static func isSchemeByte(_ byte: UInt8) -> Bool {
        (byte >= 97 && byte <= 122) ||
            (byte >= 48 && byte <= 57) ||
            byte == 43 ||
            byte == 45 ||
            byte == 46
    }
}
