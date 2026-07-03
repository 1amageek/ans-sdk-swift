public struct VerifiedReceipt: Sendable, Hashable {
    public let treeSize: UInt64
    public let leafIndex: UInt64
    public let rootHash: [UInt8]
    public let eventBytes: [UInt8]
    public let keyID: [UInt8]

    public init(treeSize: UInt64, leafIndex: UInt64, rootHash: [UInt8], eventBytes: [UInt8], keyID: [UInt8] = []) {
        self.treeSize = treeSize
        self.leafIndex = leafIndex
        self.rootHash = rootHash
        self.eventBytes = eventBytes
        self.keyID = keyID
    }
}

#if !hasFeature(Embedded)
extension VerifiedReceipt: Codable {}
#endif
