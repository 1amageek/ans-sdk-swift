#if !hasFeature(Embedded)
public protocol TransparencyLog: Sendable {
    func badge(for agentID: Agent.ID) async throws(any Error) -> Badge
    func badge(at uri: URI) async throws(any Error) -> Badge
    func audit(agentID: Agent.ID, page: Page?) async throws(any Error) -> TransparencyAudit
    func checkpoint() async throws(any Error) -> Checkpoint
    func checkpointHistory(page: Page?) async throws(any Error) -> CheckpointHistory
    func schema(version: String) async throws(any Error) -> [UInt8]
    func receipt(agentID: Agent.ID) async throws(any Error) -> [UInt8]
    func statusToken(agentID: Agent.ID) async throws(any Error) -> [UInt8]
    func rootKeys() async throws(any Error) -> [RootKey]
    func identityBadge(for identityID: Identity.ID) async throws(any Error) -> TransparencyRecord
    func identityAudit(identityID: Identity.ID, page: Page?) async throws(any Error) -> TransparencyRecordAudit
    func identityReceipt(identityID: Identity.ID) async throws(any Error) -> [UInt8]
    func identityAgents(identityID: Identity.ID, page: Page?) async throws(any Error) -> Identity.LinkedAgentPage
    func agentIdentities(agentID: Agent.ID, page: Page?) async throws(any Error) -> Identity.LinkedIdentityPage
    func agentIdentityHistory(agentID: Agent.ID, page: Page?) async throws(any Error) -> TransparencyRecordAudit
    func rawCheckpoint() async throws(any Error) -> [UInt8]
    func tile(level: Int, index: Int) async throws(any Error) -> [UInt8]
    func partialTile(level: Int, index: Int, width: Int) async throws(any Error) -> [UInt8]
    func entryTile(index: Int) async throws(any Error) -> [UInt8]
    func partialEntryTile(index: Int, width: Int) async throws(any Error) -> [UInt8]
}
#endif
