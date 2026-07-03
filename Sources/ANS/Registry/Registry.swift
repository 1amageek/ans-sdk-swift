#if !hasFeature(Embedded)
public protocol Registry: Sendable {
    func register(_ request: Registration.Request) async throws(any Error) -> Registration.Pending
    func registerAgent(_ request: Registration.Request) async throws(any Error) -> Registration.Pending
    func listAgents(page: Page?, status: Registration.Status?) async throws(any Error) -> Agent.Page
    func agent(id: Agent.ID) async throws(any Error) -> Agent
    func agentDetails(id: Agent.ID) async throws(any Error) -> Agent
    func challengeDetails(agentID: Agent.ID) async throws(any Error) -> [Registration.Challenge]
    func verifyACME(agentID: Agent.ID) async throws(any Error) -> Registration.Status
    func validateRegistration(agentID: Agent.ID) async throws(any Error) -> Registration.Status
    func verifyDNS(agentID: Agent.ID) async throws(any Error) -> Registration.Status
    func verifyDNSRecords(agentID: Agent.ID) async throws(any Error) -> Registration.Status
    func search(_ search: Search) async throws(any Error) -> Search.Result
    func resolve(host: Host, version: VersionRequirement) async throws(any Error) -> Resolution?
    func certificates(agentID: Agent.ID, kind: Certificate.Kind) async throws(any Error) -> [Certificate]
    func agentCertificates(agentID: Agent.ID, kind: Certificate.Kind) async throws(any Error) -> [Certificate]
    func submitCSR(agentID: Agent.ID, kind: Certificate.Kind, pem: String) async throws(any Error) -> CSRSubmission
    func submitAgentCSR(agentID: Agent.ID, kind: Certificate.Kind, pem: String) async throws(any Error) -> CSRSubmission
    func csrStatus(agentID: Agent.ID, csrID: String) async throws(any Error) -> CSR
    func agentCSRStatus(agentID: Agent.ID, csrID: String) async throws(any Error) -> CSR
    func submitServerCertificateRenewal(
        agentID: Agent.ID,
        request: Renewal.Request
    ) async throws(any Error) -> Renewal.Submission
    func serverCertificateRenewalStatus(agentID: Agent.ID) async throws(any Error) -> Renewal.Status
    func cancelServerCertificateRenewal(agentID: Agent.ID) async throws(any Error)
    func verifyRenewalACME(agentID: Agent.ID) async throws(any Error) -> Renewal.Verification
    func events(page: Page?, providerID: String?, lastLogID: String?) async throws(any Error) -> EventPage
    func revoke(agentID: Agent.ID, request: RevocationRequest) async throws(any Error) -> RevocationResponse
    func revokeAgent(agentID: Agent.ID, request: RevocationRequest) async throws(any Error) -> RevocationResponse
    func registerIdentity(value: String) async throws(any Error) -> Identity.ChallengeRound
    func listIdentities(page: Page?) async throws(any Error) -> Identity.Page
    func identity(id: Identity.ID) async throws(any Error) -> Identity.Details
    func rotateIdentity(id: Identity.ID, value: String) async throws(any Error) -> Identity.ChallengeRound
    func verifyIdentityControl(id: Identity.ID, signedProofs: [String]) async throws(any Error) -> Identity.Details
    func revokeIdentity(id: Identity.ID) async throws(any Error) -> Identity.Details
    func linkIdentity(id: Identity.ID, agentIDs: [Agent.ID]) async throws(any Error) -> Identity.LinkResult
    func unlinkIdentity(id: Identity.ID, agentID: Agent.ID) async throws(any Error)
}
#endif
