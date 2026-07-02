import Foundation

public protocol Registry: Sendable {
    func register(_ request: Registration.Request) async throws -> Registration.Pending
    func agent(id: Agent.ID) async throws -> Agent
    func search(_ query: Search) async throws -> Search.Result
    func resolve(host: Host, version: VersionRequirement?) async throws -> Resolution
    func verifyACME(agent id: Agent.ID) async throws -> Agent
    func verifyDNS(agent id: Agent.ID) async throws -> Agent
    func revoke(agent id: Agent.ID, reason: Revocation.Reason) async throws -> Agent
    func identityCertificates(agent id: Agent.ID) async throws -> [Certificate]
    func serverCertificates(agent id: Agent.ID) async throws -> [Certificate]
    func events(agent id: Agent.ID) async throws -> Audit
}
