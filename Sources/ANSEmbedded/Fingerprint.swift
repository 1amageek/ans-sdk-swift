public struct Fingerprint: Sendable, Hashable, CustomStringConvertible {
    public enum Algorithm: String, Sendable, Hashable {
        case sha256 = "SHA256"
    }

    public let algorithm: Algorithm
    public let digestHex: String

    public init(algorithm: Algorithm, digestHex: String) throws {
        let normalized = Self.lowercaseHex(digestHex)
        guard normalized.count == 64 else {
            throw ParsingError("SHA256 fingerprint digest must be 32 bytes")
        }
        guard normalized.utf8.allSatisfy(Self.isHexByte) else {
            throw ParsingError("Fingerprint digest must be hexadecimal")
        }
        self.algorithm = algorithm
        self.digestHex = normalized
    }

    public init(rawValue: String) throws {
        let parts = rawValue.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2, parts[0] == Algorithm.sha256.rawValue else {
            throw ParsingError("Fingerprint must use SHA256:<hex>")
        }
        try self.init(algorithm: .sha256, digestHex: String(parts[1]))
    }

    public var rawValue: String {
        "\(algorithm.rawValue):\(digestHex)"
    }

    public var description: String { rawValue }

    private static func lowercaseHex(_ value: String) -> String {
        let bytes = value.utf8.map { byte -> UInt8 in
            if (UInt8(ascii: "A")...UInt8(ascii: "F")).contains(byte) {
                return byte + 32
            }
            return byte
        }
        return String(decoding: bytes, as: UTF8.self)
    }

    private static func isHexByte(_ byte: UInt8) -> Bool {
        (UInt8(ascii: "0")...UInt8(ascii: "9")).contains(byte)
            || (UInt8(ascii: "a")...UInt8(ascii: "f")).contains(byte)
    }
}
