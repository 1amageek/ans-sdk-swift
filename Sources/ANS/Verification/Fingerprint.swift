import CryptoKit
import Foundation

public struct Fingerprint: Sendable, Hashable, Codable, CustomStringConvertible {
    public enum Algorithm: String, Sendable, Codable {
        case sha256 = "SHA256"
    }

    public let algorithm: Algorithm
    public let digest: Data

    public init(algorithm: Algorithm, digest: Data) {
        self.algorithm = algorithm
        self.digest = digest
    }

    public init(rawValue: String) throws {
        let parts = rawValue.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2, parts[0].uppercased() == Algorithm.sha256.rawValue else {
            throw ParsingError("Fingerprint must use SHA256:<hex>")
        }
        self.algorithm = .sha256
        self.digest = try Data(ansHexString: String(parts[1]).lowercased())
    }

    public var rawValue: String {
        "\(algorithm.rawValue):\(digest.ansHexString)"
    }

    public var description: String { rawValue }

    public static func sha256(der: Data) -> Fingerprint {
        Fingerprint(algorithm: .sha256, digest: Data(SHA256.hash(data: der)))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(rawValue: container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
