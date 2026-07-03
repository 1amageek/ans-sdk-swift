public struct Checkpoint: Sendable, Hashable {
    public let logSize: Int?
    public let rootHash: String?
    public let originName: String?
    public let checkpointText: String?
    public let createdAt: String?

    public init(
        logSize: Int? = nil,
        rootHash: String? = nil,
        originName: String? = nil,
        checkpointText: String? = nil,
        createdAt: String? = nil
    ) {
        self.logSize = logSize
        self.rootHash = rootHash
        self.originName = originName
        self.checkpointText = checkpointText
        self.createdAt = createdAt
    }
}

public struct CheckpointHistory: Sendable, Hashable {
    public let checkpoints: [Checkpoint]
    public let pagination: Page?

    public init(checkpoints: [Checkpoint], pagination: Page? = nil) {
        self.checkpoints = checkpoints
        self.pagination = pagination
    }
}

#if !hasFeature(Embedded)
extension Checkpoint: Codable {}
extension CheckpointHistory: Codable {}
#endif
