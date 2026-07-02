import Foundation
import XCTest
import ANS

final class ClientTests: XCTestCase {
    func testClientUsesV1RegisterPathAndAuthHeader() async throws {
        let pending = ANS::Registration.Pending(
            agentID: ANS::Agent.ID("agent-1"),
            name: try ANS::Name(rawValue: "ans://v1.0.0.agent.example.com"),
            status: .pendingValidation
        )
        let body = try JSONEncoder().encode(pending)
        let transport = FakeTransport(response: ANS::Response(statusCode: 200, body: body))
        let client = ANS::Client(
            configuration: ANS::Configuration(
                registryBaseURL: URL(string: "https://api.example.com")!,
                credential: .apiKey(key: "key", secret: "secret")
            ),
            transport: transport
        )

        let host = try ANS::Host(rawValue: "agent.example.com")
        let endpoint = ANS::Endpoint(url: URL(string: "https://agent.example.com/mcp")!, protocolKind: .mcp)
        _ = try await client.register(
            try ANS::Registration.Request(
                displayName: "Agent",
                host: host,
                endpoints: [endpoint],
                version: try ANS::Version("1.0.0"),
                identityCSR: "csr"
            )
        )

        let request = await transport.lastRequest
        XCTAssertEqual(request?.url.path, "/v1/agents/register")
        XCTAssertEqual(request?.headers["Authorization"], "sso-key key:secret")
        XCTAssertEqual(request?.method, .post)
    }

    func testRootKeysParseTextResponse() async throws {
        let rawKey = Data([0x02]) + Data(repeating: 0x01, count: 10)
        let line = "ans.example+\(Data([0xaa, 0xbb, 0xcc, 0xdd]).ansTestHexString)+\(rawKey.base64EncodedString())\n"
        let transport = FakeTransport(response: ANS::Response(statusCode: 200, body: Data(line.utf8)))
        let client = ANS::Client(configuration: ANS::Configuration(registryBaseURL: URL(string: "https://api.example.com")!), transport: transport)

        let keys = try await client.rootKeys()

        XCTAssertEqual(keys.count, 1)
        XCTAssertEqual(keys[0].origin, "ans.example")
        XCTAssertEqual(keys[0].keyID, Data([0xaa, 0xbb, 0xcc, 0xdd]))
        XCTAssertEqual(keys[0].spkiDER, Data(repeating: 0x01, count: 10))
    }
}

private actor FakeTransport: ANS::Transport {
    private let response: ANS::Response
    private(set) var lastRequest: ANS::Request?

    init(response: ANS::Response) {
        self.response = response
    }

    func send(_ request: ANS::Request) async throws -> ANS::Response {
        lastRequest = request
        return response
    }
}

private extension Data {
    var ansTestHexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
