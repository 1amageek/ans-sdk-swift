import Foundation

public protocol TransparencyLog: Sendable {
    func badge(for agent: Agent.ID) async throws -> Badge
    func badge(at url: URL) async throws -> Badge
    func audit(for agent: Agent.ID, page: Page?) async throws -> Audit
    func receipt(for agent: Agent.ID) async throws -> Receipt
    func statusToken(for agent: Agent.ID) async throws -> Token
    func checkpoint() async throws -> Checkpoint
    func checkpointHistory(page: Page?) async throws -> [Checkpoint]
    func schema(version: String) async throws -> Data
    func rootKeys() async throws -> [RootKey]
}
