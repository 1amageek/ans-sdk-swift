import Foundation
import Testing
import ANS

@Test(.timeLimit(.minutes(1)))
func clientUsesV1RegisterPathAndAuthHeader() async throws {
    let pending = Registration.Pending(
        agentID: Agent.ID("agent-1"),
        name: try Name(rawValue: "ans://v1.0.0.agent.example.com"),
        status: .pendingValidation
    )
    let body = try JSONEncoder().encode(pending)
    let transport = FakeTransport(response: Response(statusCode: 200, body: body))
    let client = Client(
        configuration: Configuration(
            registryBaseURL: URL(string: "https://api.example.com")!,
            credential: .apiKey(key: "key", secret: "secret"),
            additionalHeaders: ["authorization": "Bearer leaked"]
        ),
        transport: transport
    )

    let host = try Host(rawValue: "agent.example.com")
    let endpoint = Endpoint(url: URL(string: "https://agent.example.com/mcp")!, protocolKind: .mcp)
    _ = try await client.register(
        try Registration.Request(
            displayName: "Agent",
            host: host,
            endpoints: [endpoint],
            version: try Version("1.0.0"),
            identityCSR: "csr"
        )
    )

    let request = try #require(await transport.recordedRequest())
    #expect(request.url.path == "/v1/agents/register")
    #expect(request.headers["Authorization"] == "sso-key key:secret")
    #expect(request.method == .post)
}

@Test(.timeLimit(.minutes(1)))
func badgeURLRequestDoesNotSendAuthorization() async throws {
    let host = try Host(rawValue: "agent.example.com")
    let fingerprint = Fingerprint.sha256(der: Data([1, 2, 3]))
    let badge = Badge(host: host, status: .active, serverFingerprints: [fingerprint])
    let body = try JSONEncoder().encode(badge)
    let transport = FakeTransport(response: Response(statusCode: 200, body: body))
    let client = Client(
        configuration: Configuration(
            registryBaseURL: URL(string: "https://api.example.com")!,
            credential: .apiKey(key: "key", secret: "secret")
        ),
        transport: transport
    )

    _ = try await client.badge(at: URL(string: "https://tl.example.com/v1/agents/agent-1")!)

    let request = try #require(await transport.recordedRequest())
    #expect(request.headers["Authorization"] == nil)
    #expect(request.headers["authorization"] == nil)
    #expect(request.headers["Accept"] == "application/json")
}

@Test(.timeLimit(.minutes(1)))
func rootKeysParseTextResponse() async throws {
    let rawKey = Data([0x02]) + Data(repeating: 0x01, count: 10)
    let line = "ans.example+\(Data([0xaa, 0xbb, 0xcc, 0xdd]).ansTestHexString)+\(rawKey.base64EncodedString())\n"
    let transport = FakeTransport(response: Response(statusCode: 200, body: Data(line.utf8)))
    let client = Client(configuration: Configuration(registryBaseURL: URL(string: "https://api.example.com")!), transport: transport)

    let keys = try await client.rootKeys()

    #expect(keys.count == 1)
    #expect(keys[0].origin == "ans.example")
    #expect(keys[0].keyID == Data([0xaa, 0xbb, 0xcc, 0xdd]))
    #expect(keys[0].spkiDER == Data(repeating: 0x01, count: 10))
}
