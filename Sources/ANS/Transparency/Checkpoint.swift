import Foundation

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
