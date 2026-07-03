import Testing
import ANS

@Suite("RegistryClient")
struct RegistryClientTests {
    @Test(.timeLimit(.minutes(1)))
    func registerUsesV1PathAndDecodesPendingResponse() async throws {
        let transport = RecordingTransport(response: Response(
            statusCode: 202,
            body: Array("""
            {
              "status": "PENDING_VALIDATION",
              "ansName": "ans://v1.0.0.agent.example.com",
              "agentId": "agent-1",
              "nextSteps": [{"action": "VERIFY_ACME", "description": "verify"}]
            }
            """.utf8)
        ))
        let configuration = Configuration(
            registryBaseURI: try URI(rawValue: "https://registry.ans.godaddy.com")
        )
        let registry = RegistryClient(client: Client(configuration: configuration, transport: transport))
        let request = try Registration.Request(
            displayName: "Agent",
            host: try Host(rawValue: "agent.example.com"),
            endpoints: [
                Endpoint(
                    url: try URI(rawValue: "https://agent.example.com/mcp"),
                    protocolKind: .mcp,
                    transports: [.streamableHTTP]
                ),
            ],
            version: try Version("1.0.0"),
            identityCSRPEM: "-----BEGIN CERTIFICATE REQUEST-----"
        )

        let pending = try await registry.register(request)
        let sent = await transport.lastRequest()
        let sentBody = String(decoding: sent?.body ?? [], as: UTF8.self)

        #expect(pending.agent.id == Agent.ID(rawValue: "agent-1"))
        #expect(pending.agent.name == (try Name(rawValue: "ans://v1.0.0.agent.example.com")))
        #expect(sent?.method == .post)
        #expect(sent?.uri.rawValue == "https://registry.ans.godaddy.com/v1/agents/register")
        #expect(sentBody.contains("\"agentDisplayName\":\"Agent\""))
    }

    @Test(.timeLimit(.minutes(1)))
    func submitServerRenewalUsesV2PathAndBody() async throws {
        let transport = RecordingTransport(response: Response(
            statusCode: 202,
            body: Array("""
            {
              "renewalType": "SERVER_CSR",
              "status": "PENDING_VALIDATION",
              "csrId": "csr-1",
              "expiresAt": "2026-07-03T00:00:00Z",
              "nextStep": {"kind": "VERIFY_ACME", "message": "verify"}
            }
            """.utf8)
        ))
        let configuration = Configuration(
            registryBaseURI: try URI(rawValue: "https://registry.ans.godaddy.com/v2")
        )
        let registry = RegistryClient(client: Client(configuration: configuration, transport: transport))

        let renewal = try await registry.submitServerCertificateRenewal(
            agentID: Agent.ID(rawValue: "agent-1"),
            request: Renewal.Request(serverCSRPEM: "csr")
        )
        let sent = await transport.lastRequest()
        let sentBody = String(decoding: sent?.body ?? [], as: UTF8.self)

        #expect(renewal.csrID == "csr-1")
        #expect(sent?.method == .post)
        #expect(sent?.uri.rawValue == "https://registry.ans.godaddy.com/v2/ans/agents/agent-1/certificates/server/renewal")
        #expect(sentBody.contains("\"serverCsrPEM\":\"csr\""))
    }

    @Test(.timeLimit(.minutes(1)))
    func registerIdentityPreservesV2BasePath() async throws {
        let transport = RecordingTransport(response: Response(
            statusCode: 202,
            body: Array("""
            {
              "identityId": "identity-1",
              "kind": "did:web",
              "value": "did:web:identity.example.com",
              "status": "PENDING_CONTROL",
              "nonce": "nonce",
              "expiresAt": "2026-07-03T00:00:00Z",
              "challenges": [{"kid": "key-1", "signingInput": "input"}]
            }
            """.utf8)
        ))
        let configuration = Configuration(
            registryBaseURI: try URI(rawValue: "https://registry.ans.godaddy.com/v2")
        )
        let registry = RegistryClient(client: Client(configuration: configuration, transport: transport))

        let challenge = try await registry.registerIdentity(value: "did:web:identity.example.com")
        let sent = await transport.lastRequest()

        #expect(challenge.id == Identity.ID(rawValue: "identity-1"))
        #expect(challenge.status == .pendingControl)
        #expect(challenge.challenges.first?.keyID == "key-1")
        #expect(sent?.method == .post)
        #expect(sent?.uri.rawValue == "https://registry.ans.godaddy.com/v2/ans/identities")
    }

    @Test(.timeLimit(.minutes(1)))
    func linkIdentityUsesBatchEndpoint() async throws {
        let transport = RecordingTransport(response: Response(
            statusCode: 200,
            body: Array(#"{"linked":1}"#.utf8)
        ))
        let configuration = Configuration(
            registryBaseURI: try URI(rawValue: "https://registry.ans.godaddy.com/v2")
        )
        let registry = RegistryClient(client: Client(configuration: configuration, transport: transport))

        let result = try await registry.linkIdentity(
            id: Identity.ID(rawValue: "identity-1"),
            agentIDs: [Agent.ID(rawValue: "agent-1")]
        )
        let sent = await transport.lastRequest()
        let sentBody = String(decoding: sent?.body ?? [], as: UTF8.self)

        #expect(result.linked == 1)
        #expect(sent?.method == .post)
        #expect(sent?.uri.rawValue == "https://registry.ans.godaddy.com/v2/ans/identities/identity-1/links")
        #expect(sentBody.contains("\"agentIds\":[\"agent-1\"]"))
    }

    @Test(.timeLimit(.minutes(1)))
    func registerAgentUsesV2CollectionPath() async throws {
        let transport = RecordingTransport(response: Response(
            statusCode: 202,
            body: Array("""
            {
              "status": "PENDING_VALIDATION",
              "ansName": "ans://v1.0.0.agent.example.com",
              "agentId": "agent-1",
              "nextSteps": [{"action": "VERIFY_ACME", "description": "verify"}]
            }
            """.utf8)
        ))
        let configuration = Configuration(
            registryBaseURI: try URI(rawValue: "https://registry.ans.godaddy.com/v2")
        )
        let registry = RegistryClient(client: Client(configuration: configuration, transport: transport))
        let request = try Registration.Request(
            displayName: "Agent",
            host: try Host(rawValue: "agent.example.com"),
            endpoints: [
                Endpoint(
                    url: try URI(rawValue: "https://agent.example.com/mcp"),
                    protocolKind: .mcp,
                    transports: [.streamableHTTP]
                ),
            ],
            version: try Version("1.0.0")
        )

        let pending = try await registry.registerAgent(request)
        let sent = await transport.lastRequest()
        let sentBody = String(decoding: sent?.body ?? [], as: UTF8.self)

        #expect(pending.agent.id == Agent.ID(rawValue: "agent-1"))
        #expect(sent?.method == .post)
        #expect(sent?.uri.rawValue == "https://registry.ans.godaddy.com/v2/ans/agents")
        #expect(sentBody.contains("\"version\":\"1.0.0\""))
        #expect(!sentBody.contains("identityCsrPEM"))
    }

    @Test(.timeLimit(.minutes(1)))
    func legacyRegisterRequiresIdentityCSR() async throws {
        let transport = RecordingTransport(response: Response(statusCode: 202, body: []))
        let configuration = Configuration(
            registryBaseURI: try URI(rawValue: "https://registry.ans.godaddy.com")
        )
        let registry = RegistryClient(client: Client(configuration: configuration, transport: transport))
        let request = try Registration.Request(
            displayName: "Agent",
            host: try Host(rawValue: "agent.example.com"),
            endpoints: [
                Endpoint(
                    url: try URI(rawValue: "https://agent.example.com/mcp"),
                    protocolKind: .mcp,
                    transports: [.streamableHTTP]
                ),
            ],
            version: try Version("1.0.0")
        )

        do {
            _ = try await registry.register(request)
            #expect(Bool(false))
        } catch {
            #expect(error as? ValidationError == .missingIdentityCSRPEM)
        }

        #expect(await transport.lastRequest() == nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func listAgentsDecodesV2CollectionResponse() async throws {
        let transport = RecordingTransport(response: Response(
            statusCode: 200,
            body: Array("""
            {
              "items": [
                {
                  "agentId": "agent-1",
                  "ansName": "ans://v1.2.3.agent.example.com",
                  "agentDisplayName": "Agent",
                  "agentDescription": "desc",
                  "version": "1.2.3",
                  "agentHost": "agent.example.com",
                  "status": "ACTIVE",
                  "ttl": 300,
                  "registrationTimestamp": "2026-07-03T00:00:00Z",
                  "endpoints": [
                    {
                      "agentUrl": "https://agent.example.com/mcp",
                      "protocol": "MCP",
                      "transports": ["STREAMABLE-HTTP"],
                      "functions": []
                    }
                  ],
                  "links": [{"href": "/ans/agents/agent-1", "rel": "self"}]
                }
              ],
              "returnedCount": 1,
              "limit": 20,
              "nextCursor": "cursor-2",
              "hasMore": true
            }
            """.utf8)
        ))
        let configuration = Configuration(
            registryBaseURI: try URI(rawValue: "https://registry.ans.godaddy.com/v2")
        )
        let registry = RegistryClient(client: Client(configuration: configuration, transport: transport))

        let page = try await registry.listAgents(page: Page(limit: 20, cursor: "cursor-1"), status: .active)
        let sent = await transport.lastRequest()

        #expect(page.items.first?.id == Agent.ID(rawValue: "agent-1"))
        #expect(page.items.first?.links.first?.rel == "self")
        #expect(page.nextCursor == "cursor-2")
        #expect(page.hasMore)
        #expect(sent?.uri.rawValue == "https://registry.ans.godaddy.com/v2/ans/agents?limit=20&cursor=cursor-1&status=ACTIVE")
    }

    @Test(.timeLimit(.minutes(1)))
    func revokeAgentDecodesV2ResponseDetails() async throws {
        let transport = RecordingTransport(response: Response(
            statusCode: 200,
            body: Array("""
            {
              "agentId": "agent-1",
              "ansName": "ans://v1.0.0.agent.example.com",
              "status": "REVOKED",
              "revokedAt": "2026-07-03T00:00:00Z",
              "reason": "KEY_COMPROMISE",
              "dnsRecordsToRemove": [
                {"name": "_ans-badge.agent.example.com", "type": "TXT", "value": "remove"}
              ],
              "links": [{"href": "/ans/agents/agent-1", "rel": "self"}]
            }
            """.utf8)
        ))
        let configuration = Configuration(
            registryBaseURI: try URI(rawValue: "https://registry.ans.godaddy.com/v2")
        )
        let registry = RegistryClient(client: Client(configuration: configuration, transport: transport))

        let response = try await registry.revokeAgent(
            agentID: Agent.ID(rawValue: "agent-1"),
            request: RevocationRequest(reason: .keyCompromise)
        )
        let sent = await transport.lastRequest()

        #expect(response.name == (try Name(rawValue: "ans://v1.0.0.agent.example.com")))
        #expect(response.reason == .keyCompromise)
        #expect(response.dnsRecordsToRemove.first?.name == "_ans-badge.agent.example.com")
        #expect(sent?.method == .post)
        #expect(sent?.uri.rawValue == "https://registry.ans.godaddy.com/v2/ans/agents/agent-1/revoke")
    }
}

private actor RecordingTransport: Transport {
    private let response: Response
    private var request: Request?

    init(response: Response) {
        self.response = response
    }

    func send(_ request: Request) async throws(any Error) -> Response {
        self.request = request
        return response
    }

    func lastRequest() -> Request? {
        request
    }
}
