import CryptoKit
import Foundation

public struct Proof: Sendable, Hashable, Codable {
    public let treeSize: UInt64
    public let leafIndex: UInt64
    public let leafHash: Data
    public let path: [Data]
    public let rootHash: Data

    public init(treeSize: UInt64, leafIndex: UInt64, leafHash: Data, path: [Data], rootHash: Data) {
        self.treeSize = treeSize
        self.leafIndex = leafIndex
        self.leafHash = leafHash
        self.path = path
        self.rootHash = rootHash
    }

    public static func leafHash(payload: Data) -> Data {
        var data = Data([0x00])
        data.append(payload)
        return Data(SHA256.hash(data: data))
    }

    public func verifies(payload: Data) -> Bool {
        leafHash == Self.leafHash(payload: payload) && verifiesLeafHash()
    }

    public func verifiesLeafHash() -> Bool {
        var computed = leafHash
        var index = leafIndex

        for sibling in path {
            var node = Data()
            if index.isMultiple(of: 2) {
                node.append(computed)
                node.append(sibling)
            } else {
                node.append(sibling)
                node.append(computed)
            }
            computed = Data(SHA256.hash(data: node))
            index /= 2
        }

        return computed == rootHash
    }
}

public struct Checkpoint: Sendable, Hashable, Codable {
    public let origin: String
    public let treeSize: UInt64
    public let rootHash: Data
    public let signature: Data
    public let rawBytes: Data

    public init(origin: String, treeSize: UInt64, rootHash: Data, signature: Data, rawBytes: Data = Data()) {
        self.origin = origin
        self.treeSize = treeSize
        self.rootHash = rootHash
        self.signature = signature
        self.rawBytes = rawBytes
    }
}

public struct RootKey: Sendable, Hashable, Codable {
    public let origin: String
    public let keyID: Data
    public let spkiDER: Data
    public let rawLine: String

    public init(origin: String, keyID: Data, spkiDER: Data, rawLine: String) {
        self.origin = origin
        self.keyID = keyID
        self.spkiDER = spkiDER
        self.rawLine = rawLine
    }

    public init(line: String) throws {
        let parts = line.split(separator: "+", omittingEmptySubsequences: false)
        guard parts.count == 3 else {
            throw ParsingError("Root key line must have origin, key hash, and key material")
        }
        let keyID = try Data(ansHexString: String(parts[1]))
        guard let encoded = Data(base64Encoded: String(parts[2])), encoded.first == 0x02 else {
            throw ParsingError("Root key material must be base64(0x02 || SPKI-DER)")
        }
        self.origin = String(parts[0])
        self.keyID = keyID
        self.spkiDER = encoded.dropFirst()
        self.rawLine = line
    }
}
