import Crypto

public struct Fingerprint: Sendable, Hashable, CustomStringConvertible {
    public enum Algorithm: String, Sendable, Hashable {
        case sha256 = "SHA256"
    }

    public let algorithm: Algorithm
    public let bytes: [UInt8]

    public var rawValue: String {
        "\(algorithm.rawValue):\(Hex.encode(bytes))"
    }

    public var description: String {
        rawValue
    }

    public init(rawValue: String) throws(ParsingError) {
        let parts = rawValue.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 2 else {
            throw ParsingError.invalidFingerprint(rawValue)
        }

        guard let algorithm = Algorithm(rawValue: String(parts[0]).uppercased()) else {
            throw ParsingError.unsupportedAlgorithm(String(parts[0]))
        }

        let bytes = try Hex.decode(String(parts[1]))
        switch algorithm {
        case .sha256:
            guard bytes.count == 32 else {
                throw ParsingError.invalidFingerprint(rawValue)
            }
        }

        self.algorithm = algorithm
        self.bytes = bytes
    }

    public init(algorithm: Algorithm, bytes: [UInt8]) throws(ParsingError) {
        switch algorithm {
        case .sha256:
            guard bytes.count == 32 else {
                throw ParsingError.invalidFingerprint("\(algorithm.rawValue):\(Hex.encode(bytes))")
            }
        }

        self.algorithm = algorithm
        self.bytes = bytes
    }

    public static func sha256<Bytes: Sequence>(bytes: Bytes) throws(ParsingError) -> Fingerprint where Bytes.Element == UInt8 {
        let digest = SHA256.hash(data: Array(bytes))
        return try Fingerprint(algorithm: .sha256, bytes: Array(digest))
    }
}

#if !hasFeature(Embedded)
extension Fingerprint.Algorithm: Codable {}

extension Fingerprint: Codable {
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
