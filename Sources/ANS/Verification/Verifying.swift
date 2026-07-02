import Foundation

public protocol Verifying: Sendable {
    func verifyServer(host: Host, chain: [Certificate], policy: Policy) async throws -> Outcome
    func verifyClient(chain: [Certificate], policy: Policy) async throws -> Outcome
}

extension Verifying {
    public func verifyServer(host: Host, chain: [Certificate]) async throws -> Outcome {
        try await verifyServer(host: host, chain: chain, policy: .default)
    }

    public func verifyClient(chain: [Certificate]) async throws -> Outcome {
        try await verifyClient(chain: chain, policy: .default)
    }
}
