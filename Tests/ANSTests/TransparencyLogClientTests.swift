import Testing
import ANS

@Suite("TransparencyLogClient")
struct TransparencyLogClientTests {
    @Test(.timeLimit(.minutes(1)))
    func identityReceiptUsesPublicIdentityReceiptPath() async throws {
        let transport = RecordingTransport(response: Response(statusCode: 200, body: [1, 2, 3]))
        let configuration = Configuration(
            registryBaseURI: try URI(rawValue: "https://registry.ans.godaddy.com"),
            transparencyLogBaseURI: try URI(rawValue: "https://tl.ans.godaddy.com")
        )
        let log = TransparencyLogClient(client: Client(configuration: configuration, transport: transport))

        let bytes = try await log.identityReceipt(identityID: Identity.ID(rawValue: "identity-1"))
        let sent = await transport.lastRequest()

        #expect(bytes == [1, 2, 3])
        #expect(sent?.method == .get)
        #expect(sent?.uri.rawValue == "https://tl.ans.godaddy.com/v1/identities/identity-1/receipt")
    }

    @Test(.timeLimit(.minutes(1)))
    func rawTileUsesC2SPRootPath() async throws {
        let transport = RecordingTransport(response: Response(statusCode: 200, body: [9, 8, 7]))
        let configuration = Configuration(
            registryBaseURI: try URI(rawValue: "https://registry.ans.godaddy.com"),
            transparencyLogBaseURI: try URI(rawValue: "https://tl.ans.godaddy.com")
        )
        let log = TransparencyLogClient(client: Client(configuration: configuration, transport: transport))

        let bytes = try await log.partialTile(level: 2, index: 3, width: 4)
        let sent = await transport.lastRequest()

        #expect(bytes == [9, 8, 7])
        #expect(sent?.method == .get)
        #expect(sent?.uri.rawValue == "https://tl.ans.godaddy.com/tile/2/3.p/4")
    }

    @Test(.timeLimit(.minutes(1)))
    func agentIdentitiesDecodesComputedJoin() async throws {
        let transport = RecordingTransport(response: Response(
            statusCode: 200,
            body: Array("""
            {
              "identities": [
                {
                  "identityId": "identity-1",
                  "kind": "did:web",
                  "value": "did:web:identity.example.com",
                  "identityStatus": "VERIFIED",
                  "linkedAt": "2026-07-03T00:00:00Z",
                  "linkLogId": "log-1"
                }
              ],
              "total": 1
            }
            """.utf8)
        ))
        let configuration = Configuration(
            registryBaseURI: try URI(rawValue: "https://registry.ans.godaddy.com"),
            transparencyLogBaseURI: try URI(rawValue: "https://tl.ans.godaddy.com")
        )
        let log = TransparencyLogClient(client: Client(configuration: configuration, transport: transport))

        let page = try await log.agentIdentities(agentID: Agent.ID(rawValue: "agent-1"), page: Page(limit: 20))
        let sent = await transport.lastRequest()

        #expect(page.total == 1)
        #expect(page.identities.first?.id == Identity.ID(rawValue: "identity-1"))
        #expect(sent?.uri.rawValue == "https://tl.ans.godaddy.com/v1/agents/agent-1/identities?limit=20")
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
