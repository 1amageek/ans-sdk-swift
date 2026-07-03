import Crypto

public struct MerkleProof: Sendable, Hashable {
    public enum Direction: String, Sendable, Hashable {
        case left
        case right
    }

    public struct Step: Sendable, Hashable {
        public let direction: Direction
        public let hash: [UInt8]

        public init(direction: Direction, hash: [UInt8]) {
            self.direction = direction
            self.hash = hash
        }
    }

    public let leafIndex: UInt64
    public let treeSize: UInt64
    public let rootHash: [UInt8]
    public let steps: [Step]

    public init(leafIndex: UInt64, treeSize: UInt64, rootHash: [UInt8], steps: [Step]) {
        self.leafIndex = leafIndex
        self.treeSize = treeSize
        self.rootHash = rootHash
        self.steps = steps
    }

    public func verify(leafBytes: [UInt8]) -> Bool {
        var current = Self.leafHash(leafBytes)
        for step in steps {
            switch step.direction {
            case .left:
                current = Self.nodeHash(left: step.hash, right: current)
            case .right:
                current = Self.nodeHash(left: current, right: step.hash)
            }
        }
        return current == rootHash
    }

    public static func leafHash(_ bytes: [UInt8]) -> [UInt8] {
        var input: [UInt8] = [0x00]
        input.append(contentsOf: bytes)
        return Array(SHA256.hash(data: input))
    }

    public static func nodeHash(left: [UInt8], right: [UInt8]) -> [UInt8] {
        var input: [UInt8] = [0x01]
        input.append(contentsOf: left)
        input.append(contentsOf: right)
        return Array(SHA256.hash(data: input))
    }
}

#if !hasFeature(Embedded)
extension MerkleProof.Direction: Codable {}
extension MerkleProof.Step: Codable {}
extension MerkleProof: Codable {}
#endif
