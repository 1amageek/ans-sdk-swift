public struct Host: Sendable, Hashable, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) throws {
        let normalized = Self.asciiLowercase(rawValue)
        try Self.validate(normalized)
        self.rawValue = normalized
    }

    public init(_ rawValue: String) throws {
        try self.init(rawValue: rawValue)
    }

    public var description: String { rawValue }

    private static func validate(_ value: String) throws {
        let bytes = Array(value.utf8)
        guard !bytes.isEmpty else {
            throw ParsingError("Host must not be empty")
        }
        guard bytes.count <= 237 else {
            throw ParsingError("Host exceeds ANS length limit")
        }
        guard bytes.last != UInt8(ascii: ".") else {
            throw ParsingError("Host must not include a trailing dot")
        }
        guard bytes.contains(UInt8(ascii: ".")) else {
            throw ParsingError("Host must be a fully qualified domain name")
        }
        guard !isIPv4(bytes), !bytes.contains(UInt8(ascii: ":")) else {
            throw ParsingError("Host must not be an IP literal")
        }

        var labelLength = 0
        var previous: UInt8?

        for byte in bytes {
            if byte == UInt8(ascii: ".") {
                try validateLabel(length: labelLength, first: previous)
                labelLength = 0
                previous = nil
                continue
            }

            if labelLength == 0, byte == UInt8(ascii: "-") {
                throw ParsingError("Host labels must not start or end with a hyphen")
            }
            guard isHostByte(byte) else {
                throw ParsingError("Host labels must contain only letters, digits, or hyphens")
            }
            previous = byte
            labelLength += 1
        }

        try validateLabel(length: labelLength, first: previous)
    }

    private static func validateLabel(length: Int, first previous: UInt8?) throws {
        guard length > 0 else {
            throw ParsingError("Host labels must not be empty")
        }
        guard length <= 63 else {
            throw ParsingError("Host label exceeds 63 octets")
        }
        guard previous != UInt8(ascii: "-") else {
            throw ParsingError("Host labels must not start or end with a hyphen")
        }
    }

    private static func isHostByte(_ byte: UInt8) -> Bool {
        (UInt8(ascii: "a")...UInt8(ascii: "z")).contains(byte)
            || (UInt8(ascii: "0")...UInt8(ascii: "9")).contains(byte)
            || byte == UInt8(ascii: "-")
    }

    private static func isIPv4(_ bytes: [UInt8]) -> Bool {
        var parts = 1
        var current = 0
        var digits = 0

        for byte in bytes {
            if byte == UInt8(ascii: ".") {
                guard digits > 0, current <= 255 else { return false }
                parts += 1
                current = 0
                digits = 0
                continue
            }
            guard (UInt8(ascii: "0")...UInt8(ascii: "9")).contains(byte) else {
                return false
            }
            current = current * 10 + Int(byte - UInt8(ascii: "0"))
            digits += 1
        }

        return parts == 4 && digits > 0 && current <= 255
    }

    private static func asciiLowercase(_ value: String) -> String {
        let bytes = value.utf8.map { byte -> UInt8 in
            if (UInt8(ascii: "A")...UInt8(ascii: "Z")).contains(byte) {
                return byte + 32
            }
            return byte
        }
        return String(decoding: bytes, as: UTF8.self)
    }
}
