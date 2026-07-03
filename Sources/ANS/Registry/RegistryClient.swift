#if !hasFeature(Embedded)
public struct RegistryClient: Registry {
    private let client: Client

    public init(client: Client) {
        self.client = client
    }

    public func register(_ request: Registration.Request) async throws(any Error) -> Registration.Pending {
        guard request.identityCSRPEM != nil else {
            throw ValidationError.missingIdentityCSRPEM
        }

        let response = try await client.post(
            RegistrationPendingDTO.self,
            path: client.paths.registerPath,
            body: RegistrationRequestDTO(request)
        )
        return try response.pending()
    }

    public func registerAgent(_ request: Registration.Request) async throws(any Error) -> Registration.Pending {
        let response = try await client.post(
            RegistrationPendingDTO.self,
            path: client.paths.agentsPath,
            body: RegistrationRequestDTO(request)
        )
        return try response.pending()
    }

    public func listAgents(page: Page? = nil, status: Registration.Status? = nil) async throws(any Error) -> Agent.Page {
        let queryItems = [
            ("limit", page?.limit.map(String.init)),
            ("cursor", page?.cursor),
            ("status", status?.rawValue),
        ]
        return try await client.get(AgentListResponseDTO.self, path: client.paths.agentsPath, queryItems: queryItems).page()
    }

    public func agent(id: Agent.ID) async throws(any Error) -> Agent {
        try await client.get(AgentDetailsDTO.self, path: client.paths.agentPath(id: id)).agent()
    }

    public func agentDetails(id: Agent.ID) async throws(any Error) -> Agent {
        try await client.get(AgentDetailsDTO.self, path: client.paths.v2AgentPath(id: id)).agent()
    }

    public func challengeDetails(agentID: Agent.ID) async throws(any Error) -> [Registration.Challenge] {
        try await client.get(
            ChallengeDetailsDTO.self,
            path: client.paths.challengePath(agentID: agentID)
        ).challenges.map { $0.challenge() }
    }

    public func verifyACME(agentID: Agent.ID) async throws(any Error) -> Registration.Status {
        try await client.post(StatusDTO.self, path: client.paths.verifyACMEPath(agentID: agentID)).status
    }

    public func validateRegistration(agentID: Agent.ID) async throws(any Error) -> Registration.Status {
        try await client.post(StatusDTO.self, path: client.paths.validateRegistrationPath(agentID: agentID)).status
    }

    public func verifyDNS(agentID: Agent.ID) async throws(any Error) -> Registration.Status {
        try await client.post(StatusDTO.self, path: client.paths.verifyDNSPath(agentID: agentID)).status
    }

    public func verifyDNSRecords(agentID: Agent.ID) async throws(any Error) -> Registration.Status {
        try await client.post(StatusDTO.self, path: client.paths.verifyDNSRecordsPath(agentID: agentID)).status
    }

    public func search(_ search: Search) async throws(any Error) -> Search.Result {
        let queryItems = search.queryItems()
        let response = try await client.get(SearchResponseDTO.self, path: client.paths.searchPath, queryItems: queryItems)
        return try response.result()
    }

    public func resolve(host: Host, version: VersionRequirement) async throws(any Error) -> Resolution? {
        let body = ResolutionRequestDTO(agentHost: host.rawValue, version: version.rawValue)
        let response = try await client.post(ResolutionResponseDTO.self, path: client.paths.resolutionPath, body: body)
        return try response.resolution()
    }

    public func certificates(agentID: Agent.ID, kind: Certificate.Kind) async throws(any Error) -> [Certificate] {
        let response = try await client.get(
            [CertificateDTO].self,
            path: client.paths.certificatesPath(agentID: agentID, kind: kind)
        )
        return response.map { $0.certificate() }
    }

    public func agentCertificates(agentID: Agent.ID, kind: Certificate.Kind) async throws(any Error) -> [Certificate] {
        let response = try await client.get(
            [CertificateDTO].self,
            path: client.paths.agentCertificatesPath(agentID: agentID, kind: kind)
        )
        return response.map { $0.certificate() }
    }

    public func submitCSR(agentID: Agent.ID, kind: Certificate.Kind, pem: String) async throws(any Error) -> CSRSubmission {
        let response = try await client.post(
            CSRSubmissionDTO.self,
            path: client.paths.certificatesPath(agentID: agentID, kind: kind),
            body: CSRRequestDTO(csrPEM: pem)
        )
        return response.submission()
    }

    public func submitAgentCSR(agentID: Agent.ID, kind: Certificate.Kind, pem: String) async throws(any Error) -> CSRSubmission {
        let response = try await client.post(
            CSRSubmissionDTO.self,
            path: client.paths.agentCertificatesPath(agentID: agentID, kind: kind),
            body: CSRRequestDTO(csrPEM: pem)
        )
        return response.submission()
    }

    public func csrStatus(agentID: Agent.ID, csrID: String) async throws(any Error) -> CSR {
        try await client.get(CSRStatusDTO.self, path: client.paths.csrStatusPath(agentID: agentID, csrID: csrID)).csr()
    }

    public func agentCSRStatus(agentID: Agent.ID, csrID: String) async throws(any Error) -> CSR {
        try await client.get(CSRStatusDTO.self, path: client.paths.agentCSRStatusPath(agentID: agentID, csrID: csrID)).csr()
    }

    public func submitServerCertificateRenewal(
        agentID: Agent.ID,
        request: Renewal.Request
    ) async throws(any Error) -> Renewal.Submission {
        try await client.post(
            Renewal.Submission.self,
            path: client.paths.serverCertificateRenewalPath(agentID: agentID),
            body: request
        )
    }

    public func serverCertificateRenewalStatus(agentID: Agent.ID) async throws(any Error) -> Renewal.Status {
        try await client.get(Renewal.Status.self, path: client.paths.serverCertificateRenewalPath(agentID: agentID))
    }

    public func cancelServerCertificateRenewal(agentID: Agent.ID) async throws(any Error) {
        try await client.delete(path: client.paths.serverCertificateRenewalPath(agentID: agentID))
    }

    public func verifyRenewalACME(agentID: Agent.ID) async throws(any Error) -> Renewal.Verification {
        try await client.post(Renewal.Verification.self, path: client.paths.verifyRenewalACMEPath(agentID: agentID))
    }

    public func events(page: Page? = nil, providerID: String? = nil, lastLogID: String? = nil) async throws(any Error) -> EventPage {
        var queryItems: [(String, String?)] = []
        queryItems.append(("limit", page?.limit.map(String.init)))
        queryItems.append(("providerId", providerID))
        queryItems.append(("lastLogId", lastLogID))
        let response = try await client.get(EventPageDTO.self, path: client.paths.eventsPath, queryItems: queryItems)
        return try response.page()
    }

    public func revoke(agentID: Agent.ID, request: RevocationRequest) async throws(any Error) -> RevocationResponse {
        let response = try await client.post(
            RevocationResponseDTO.self,
            path: client.paths.revokePath(agentID: agentID),
            body: RevocationRequestDTO(request)
        )
        return try response.response()
    }

    public func revokeAgent(agentID: Agent.ID, request: RevocationRequest) async throws(any Error) -> RevocationResponse {
        let response = try await client.post(
            RevocationResponseDTO.self,
            path: client.paths.v2RevokePath(agentID: agentID),
            body: RevocationRequestDTO(request)
        )
        return try response.response()
    }

    public func registerIdentity(value: String) async throws(any Error) -> Identity.ChallengeRound {
        try await client.post(
            Identity.ChallengeRound.self,
            path: client.paths.identitiesPath,
            body: IdentityRegistrationRequestDTO(value: value)
        )
    }

    public func listIdentities(page: Page? = nil) async throws(any Error) -> Identity.Page {
        let queryItems = [
            ("limit", page?.limit.map(String.init)),
            ("cursor", page?.cursor),
        ]
        return try await client.get(Identity.Page.self, path: client.paths.identitiesPath, queryItems: queryItems)
    }

    public func identity(id: Identity.ID) async throws(any Error) -> Identity.Details {
        try await client.get(Identity.Details.self, path: client.paths.identityPath(id: id))
    }

    public func rotateIdentity(id: Identity.ID, value: String) async throws(any Error) -> Identity.ChallengeRound {
        try await client.put(
            Identity.ChallengeRound.self,
            path: client.paths.identityPath(id: id),
            body: IdentityRegistrationRequestDTO(value: value)
        )
    }

    public func verifyIdentityControl(id: Identity.ID, signedProofs: [String]) async throws(any Error) -> Identity.Details {
        try await client.post(
            Identity.Details.self,
            path: client.paths.verifyIdentityControlPath(id: id),
            body: VerifyControlRequestDTO(signedProofs: signedProofs)
        )
    }

    public func revokeIdentity(id: Identity.ID) async throws(any Error) -> Identity.Details {
        try await client.post(Identity.Details.self, path: client.paths.revokeIdentityPath(id: id))
    }

    public func linkIdentity(id: Identity.ID, agentIDs: [Agent.ID]) async throws(any Error) -> Identity.LinkResult {
        try await client.post(
            Identity.LinkResult.self,
            path: client.paths.identityLinksPath(id: id),
            body: IdentityLinkRequestDTO(agentIds: agentIDs)
        )
    }

    public func unlinkIdentity(id: Identity.ID, agentID: Agent.ID) async throws(any Error) {
        try await client.delete(path: client.paths.identityLinkPath(id: id, agentID: agentID))
    }
}

private extension Search {
    func queryItems() -> [(String, String?)] {
        var items: [(String, String?)] = []
        items.append(("agentHost", host?.rawValue))
        items.append(("agentDisplayName", displayName))
        items.append(("version", version?.rawValue))
        items.append(("protocol", protocolKind?.rawValue))
        for status in statuses {
            items.append(("status", status.rawValue))
        }
        items.append(("limit", page?.limit.map(String.init)))
        items.append(("offset", page?.offset.map(String.init)))
        return items
    }
}

private struct RegistrationRequestDTO: Encodable {
    let agentDisplayName: String
    let agentHost: String
    let agentDescription: String?
    let identityCsrPEM: String?
    let serverCertificatePEM: String?
    let serverCertificateChainPEM: String?
    let serverCsrPEM: String?
    let version: String
    let endpoints: [EndpointDTO]
    let discoveryProfiles: [String]

    init(_ request: Registration.Request) {
        self.agentDisplayName = request.displayName
        self.agentHost = request.host.rawValue
        self.agentDescription = request.description
        self.identityCsrPEM = request.identityCSRPEM
        self.serverCertificatePEM = request.serverCertificatePEM
        self.serverCertificateChainPEM = request.serverCertificateChainPEM
        self.serverCsrPEM = request.serverCSRPEM
        self.version = request.version.rawValue
        self.endpoints = request.endpoints.map(EndpointDTO.init)
        self.discoveryProfiles = request.discoveryProfiles.map(\.rawValue)
    }
}

private struct EndpointDTO: Codable {
    let agentUrl: String
    let metaDataUrl: String?
    let documentationUrl: String?
    let `protocol`: String
    let transports: [String]
    let functions: [FunctionDTO]

    init(_ endpoint: Endpoint) {
        self.agentUrl = endpoint.url.rawValue
        self.metaDataUrl = endpoint.metadataURL?.rawValue
        self.documentationUrl = endpoint.documentationURL?.rawValue
        self.protocol = endpoint.protocolKind.rawValue
        self.transports = endpoint.transports.map(\.rawValue)
        self.functions = endpoint.functions.map(FunctionDTO.init)
    }

    func endpoint() throws(any Error) -> Endpoint {
        try Endpoint(
            url: URI(rawValue: agentUrl),
            protocolKind: Endpoint.ProtocolKind(rawValue: `protocol`),
            transports: transports.map(Endpoint.TransportKind.init(rawValue:)),
            metadataURL: metaDataUrl.map { try URI(rawValue: $0) },
            metadataHash: nil,
            documentationURL: documentationUrl.map { try URI(rawValue: $0) },
            functions: functions.map { $0.function() }
        )
    }
}

private struct FunctionDTO: Codable {
    let id: String
    let name: String
    let tags: [String]?

    init(_ function: Function) {
        self.id = function.id
        self.name = function.name
        self.tags = function.tags
    }

    func function() -> Function {
        Function(id: id, name: name, tags: tags ?? [])
    }
}

private struct RegistrationPendingDTO: Decodable {
    let status: String?
    let ansName: String
    let agentId: String?
    let challenges: [ChallengeDTO]?
    let dnsRecords: [DNSRecordDTO]?
    let expiresAt: String?
    let links: [LinkDTO]?
    let nextSteps: [NextStepDTO]?

    func pending() throws(any Error) -> Registration.Pending {
        let name = try Name(rawValue: ansName)
        let agent = Agent(
            id: Agent.ID(rawValue: agentId ?? ansName),
            name: name,
            host: name.host,
            displayName: name.host.rawValue,
            version: name.version,
            status: status.map(Registration.Status.init(rawValue:)) ?? .pendingValidation,
            endpoints: []
        )
        return Registration.Pending(
            agent: agent,
            status: status.map(Registration.Status.init(rawValue:)),
            expiresAt: expiresAt,
            challenges: (challenges ?? []).map { $0.challenge() },
            dnsRecords: (dnsRecords ?? []).map { $0.record() },
            links: (links ?? []).map { $0.link() },
            steps: (nextSteps ?? []).map { $0.step() }
        )
    }
}

private struct ChallengeDetailsDTO: Decodable {
    let challenges: [ChallengeDTO]
}

private struct ChallengeDTO: Decodable {
    let type: String
    let token: String?
    let keyAuthorization: String?
    let httpPath: String?
    let dnsRecord: DNSRecordDTO?
    let expiresAt: String?

    func challenge() -> Registration.Challenge {
        Registration.Challenge(
            type: WireValue(type),
            token: token,
            keyAuthorization: keyAuthorization,
            httpPath: httpPath,
            dnsRecord: dnsRecord?.record(),
            expiresAt: expiresAt
        )
    }
}

private struct DNSRecordDTO: Codable {
    let name: String
    let type: String
    let value: String
    let purpose: String?
    let ttl: Int?
    let priority: Int?
    let required: Bool?

    func record() -> Registration.DNSRecord {
        Registration.DNSRecord(
            name: name,
            type: WireValue(type),
            value: value,
            purpose: purpose.map { WireValue($0) },
            ttl: ttl,
            priority: priority,
            required: required ?? false
        )
    }
}

private struct NextStepDTO: Decodable {
    let action: String
    let description: String?
    let endpoint: String?

    func step() -> Registration.Step {
        Registration.Step(kind: WireValue(action), message: description ?? endpoint ?? action)
    }
}

private struct LinkDTO: Codable {
    let href: String
    let rel: String

    func link() -> Registration.Link {
        Registration.Link(href: href, rel: rel)
    }
}

private struct StatusDTO: Decodable {
    let status: Registration.Status

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            let value = try container.decode(String.self)
            self.status = Registration.Status(rawValue: value)
            return
        } catch {
            let object = try decoder.container(keyedBy: CodingKeys.self)
            self.status = Registration.Status(rawValue: try object.decode(String.self, forKey: .status))
        }
    }

    private enum CodingKeys: String, CodingKey {
        case status
    }
}

private struct AgentDetailsDTO: Decodable {
    let agentId: String
    let agentDisplayName: String
    let agentHost: String
    let agentDescription: String?
    let ansName: String?
    let version: String?
    let ttl: Int?
    let registrationTimestamp: String?
    let lastRenewalTimestamp: String?
    let agentStatus: StatusDTO?
    let status: StatusDTO?
    let endpoints: [EndpointDTO]
    let links: [LinkDTO]?
    let identities: [Identity.LinkedIdentity]?

    func agent() throws(any Error) -> Agent {
        let host = try Host(rawValue: agentHost)
        let versionValue: Version?
        if let version {
            versionValue = try Version(version)
        } else {
            versionValue = nil
        }
        let name = try ansName.map { try Name(rawValue: $0) }
        return Agent(
            id: Agent.ID(rawValue: agentId),
            name: name,
            host: host,
            displayName: agentDisplayName,
            description: agentDescription,
            version: versionValue,
            status: agentStatus?.status ?? status?.status ?? .active,
            endpoints: try endpoints.map { try $0.endpoint() },
            ttl: ttl,
            registrationTimestamp: registrationTimestamp,
            lastRenewalTimestamp: lastRenewalTimestamp,
            links: (links ?? []).map { $0.link() },
            identities: identities ?? []
        )
    }
}

private struct AgentListResponseDTO: Decodable {
    let items: [AgentDetailsDTO]
    let returnedCount: Int
    let limit: Int
    let nextCursor: String?
    let hasMore: Bool

    func page() throws(any Error) -> Agent.Page {
        try Agent.Page(
            items: items.map { try $0.agent() },
            returnedCount: returnedCount,
            limit: limit,
            nextCursor: nextCursor,
            hasMore: hasMore
        )
    }
}

private struct SearchResponseDTO: Decodable {
    let agents: [SearchAgentDTO]
    let totalCount: Int?
    let returnedCount: Int?
    let hasMore: Bool?

    func result() throws(any Error) -> Search.Result {
        try Search.Result(
            agents: agents.map { try $0.agent() },
            totalCount: totalCount,
            returnedCount: returnedCount,
            hasMore: hasMore ?? false
        )
    }
}

private struct SearchAgentDTO: Decodable {
    let agentDisplayName: String
    let agentHost: String
    let agentDescription: String?
    let ansName: String?
    let version: String?
    let endpoints: [EndpointDTO]

    func agent() throws(any Error) -> Agent {
        let host = try Host(rawValue: agentHost)
        let parsedName = try ansName.map { try Name(rawValue: $0) }
        return Agent(
            id: Agent.ID(rawValue: ansName ?? agentHost),
            name: parsedName,
            host: host,
            displayName: agentDisplayName,
            description: agentDescription,
            version: try version.map { try Version($0) },
            status: .active,
            endpoints: try endpoints.map { try $0.endpoint() }
        )
    }
}

private struct ResolutionRequestDTO: Encodable {
    let agentHost: String
    let version: String
}

private struct ResolutionResponseDTO: Decodable {
    let agent: AgentDetailsDTO?
    let endpoint: EndpointDTO?

    func resolution() throws(any Error) -> Resolution? {
        guard let agent else {
            return nil
        }
        return try Resolution(agent: agent.agent(), endpoint: endpoint?.endpoint())
    }
}

private struct CertificateDTO: Decodable {
    let certificatePEM: String
    let certificateIssuer: String?
    let certificateSubject: String?
    let certificateSerialNumber: String?
    let certificatePublicKeyAlgorithm: String?
    let certificateSignatureAlgorithm: String?
    let certificateValidFrom: String?
    let certificateValidTo: String?
    let csrId: String?

    func certificate() -> Certificate {
        Certificate(
            pem: certificatePEM,
            issuer: certificateIssuer,
            subject: certificateSubject,
            serialNumber: certificateSerialNumber,
            validFrom: certificateValidFrom,
            validTo: certificateValidTo,
            csrID: csrId,
            publicKeyAlgorithm: certificatePublicKeyAlgorithm,
            signatureAlgorithm: certificateSignatureAlgorithm
        )
    }
}

private struct CSRRequestDTO: Encodable {
    let csrPEM: String
}

private struct CSRSubmissionDTO: Decodable {
    let csrId: String
    let message: String?

    func submission() -> CSRSubmission {
        CSRSubmission(csrID: csrId, message: message)
    }
}

private struct CSRStatusDTO: Decodable {
    let csrId: String
    let type: String
    let status: String
    let submittedAt: String?
    let updatedAt: String?
    let failureReason: String?

    func csr() -> CSR {
        CSR(
            id: csrId,
            kind: Certificate.Kind(rawValue: type) ?? .server,
            status: CSR.Status(rawValue: status) ?? .pending,
            submittedAt: submittedAt,
            updatedAt: updatedAt,
            failureReason: failureReason
        )
    }
}

private struct EventPageDTO: Decodable {
    let items: [EventDTO]
    let lastLogId: String?

    func page() throws(any Error) -> EventPage {
        try EventPage(items: items.map { try $0.event() }, lastLogID: lastLogId)
    }
}

private struct EventDTO: Decodable {
    let logId: String
    let eventType: String
    let createdAt: String?
    let expiresAt: String?
    let agentId: String?
    let ansName: String?
    let agentHost: String?
    let version: String?
    let providerId: String?
    let endpoints: [EndpointDTO]?

    func event() throws(any Error) -> Event {
        Event(
            id: logId,
            type: WireValue(eventType),
            createdAt: createdAt,
            expiresAt: expiresAt,
            agentID: agentId.map(Agent.ID.init(rawValue:)),
            name: try ansName.map { try Name(rawValue: $0) },
            host: try agentHost.map { try Host(rawValue: $0) },
            version: try version.map { try Version($0) },
            providerID: providerId,
            endpoints: try (endpoints ?? []).map { try $0.endpoint() }
        )
    }
}

private struct RevocationRequestDTO: Encodable {
    let reason: String
    let comments: String?

    init(_ request: RevocationRequest) {
        self.reason = request.reason.rawValue
        self.comments = request.comments
    }
}

private struct RevocationResponseDTO: Decodable {
    let agentId: String?
    let ansName: String?
    let status: String?
    let revokedAt: String?
    let reason: String?
    let dnsRecordsToRemove: [DNSRecordDTO]?
    let links: [LinkDTO]?
    let message: String?

    func response() throws(any Error) -> RevocationResponse {
        RevocationResponse(
            agentID: Agent.ID(rawValue: agentId ?? ""),
            name: try ansName.map { try Name(rawValue: $0) },
            status: status.map(Registration.Status.init(rawValue:)) ?? .revoked,
            revokedAt: revokedAt,
            reason: reason.map(RevocationReason.init(rawValue:)),
            dnsRecordsToRemove: (dnsRecordsToRemove ?? []).map { $0.record() },
            links: (links ?? []).map { $0.link() },
            message: message
        )
    }
}

private struct IdentityRegistrationRequestDTO: Encodable {
    let value: String
}

private struct VerifyControlRequestDTO: Encodable {
    let signedProofs: [String]
}

private struct IdentityLinkRequestDTO: Encodable {
    let agentIds: [Agent.ID]
}
#endif
