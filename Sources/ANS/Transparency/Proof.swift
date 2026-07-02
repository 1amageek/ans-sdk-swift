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
            var node = Data([0x01])
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

    public static func internalHash(left: Data, right: Data) -> Data {
        var data = Data([0x01])
        data.append(left)
        data.append(right)
        return Data(SHA256.hash(data: data))
    }
}
