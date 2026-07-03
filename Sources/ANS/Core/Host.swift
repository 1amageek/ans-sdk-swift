public struct Host: Sendable, Hashable, CustomStringConvertible {
    public let rawValue: String

    public var description: String {
        rawValue
    }

    public init(rawValue: String) throws(ParsingError) {
        let normalized = rawValue.lowercased().trimmingSuffix(".")
        guard Self.isValid(normalized) else {
            throw ParsingError.invalidHost(rawValue)
        }

        self.rawValue = normalized
    }

}

public extension Host {
    var ansBadgeName: String {
        "_ans-badge.\(rawValue)"
    }

    var raBadgeName: String {
        "_ra-badge.\(rawValue)"
    }

    func tlsaName(port: UInt16 = 443) -> String {
        "_\(port)._tcp.\(rawValue)"
    }
}

private extension String {
    func trimmingSuffix(_ suffix: String) -> String {
        guard hasSuffix(suffix) else {
            return self
        }
        return String(dropLast(suffix.count))
    }
}

#if !hasFeature(Embedded)
extension Host: Codable {
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

extension Host {
    private static func isValid(_ host: String) -> Bool {
        guard !host.isEmpty, host.utf8.count <= 253 else {
            return false
        }

        guard !host.hasPrefix("."), !host.hasSuffix("."), !host.contains(":"), !host.contains("[") else {
            return false
        }

        let labels = host.split(separator: ".", omittingEmptySubsequences: false)
        guard labels.count >= 2 else {
            return false
        }

        if isIPv4(labels) {
            return false
        }

        for label in labels {
            guard isValidLabel(label) else {
                return false
            }
        }

        return true
    }

    private static func isValidLabel(_ label: Substring) -> Bool {
        guard !label.isEmpty, label.utf8.count <= 63 else {
            return false
        }

        guard label.first != "-", label.last != "-" else {
            return false
        }

        return label.utf8.allSatisfy { byte in
            (byte >= 97 && byte <= 122) ||
                (byte >= 48 && byte <= 57) ||
                byte == 45
        }
    }

    private static func isIPv4(_ labels: [Substring]) -> Bool {
        guard labels.count == 4 else {
            return false
        }

        for label in labels {
            guard label.utf8.allSatisfy({ byte in byte >= 48 && byte <= 57 }) else {
                return false
            }

            guard let value = Int(label), value >= 0, value <= 255 else {
                return false
            }
        }

        return true
    }
}
