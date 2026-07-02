import CryptoKit
import Foundation
import Testing
import ANS

@Test(.timeLimit(.minutes(1)))
func nameParsesWithModuleSelector() throws {
    let name = try ANS::Name(rawValue: "ans://v1.2.3.agent.example.com")

    #expect(name.version == (try ANS::Version("1.2.3")))
    #expect(name.host == (try ANS::Host(rawValue: "agent.example.com")))
    #expect(name.rawValue == "ans://v1.2.3.agent.example.com")
}

@Test(.timeLimit(.minutes(1)))
func versionRejectsPrereleaseAndBuildMetadata() {
    #expect(throws: (any Error).self) {
        try ANS::Version("1.0.0-beta")
    }
    #expect(throws: (any Error).self) {
        try ANS::Version("1.0.0+build")
    }
}

@Test(.timeLimit(.minutes(1)))
func hostRejectsIPAndSingleLabel() {
    #expect(throws: (any Error).self) {
        try ANS::Host(rawValue: "127.0.0.1")
    }
    #expect(throws: (any Error).self) {
        try ANS::Host(rawValue: "localhost")
    }
}

@Test(.timeLimit(.minutes(1)))
func wireAliasesCanonicalize() {
    #expect(ANS::Endpoint.ProtocolKind("HTTP_API").rawValue == "HTTP-API")
    #expect(ANS::Endpoint.TransportKind("STREAMABLE_HTTP").rawValue == "STREAMABLE-HTTP")
    #expect(ANS::Endpoint.TransportKind("JSON_RPC").rawValue == "JSON-RPC")
}

@Test(.timeLimit(.minutes(1)))
func registrationValidatesVersionCSRPairing() throws {
    let host = try ANS::Host(rawValue: "agent.example.com")
    let endpoint = ANS::Endpoint(url: URL(string: "https://agent.example.com/mcp")!, protocolKind: .mcp)

    #expect(throws: (any Error).self) {
        try ANS::Registration.Request(
            displayName: "Agent",
            host: host,
            endpoints: [endpoint],
            version: try ANS::Version("1.0.0")
        )
    }

    _ = try ANS::Registration.Request(
        displayName: "Agent",
        host: host,
        endpoints: [endpoint],
        version: try ANS::Version("1.0.0"),
        identityCSR: "-----BEGIN CERTIFICATE REQUEST-----\n-----END CERTIFICATE REQUEST-----"
    )
}

@Test(.timeLimit(.minutes(1)))
func fingerprintSHA256() {
    let data = Data([0x01, 0x02, 0x03])
    let fingerprint = ANS::Fingerprint.sha256(der: data)
    let expected = Data(SHA256.hash(data: data)).ansTestHexString
    #expect(fingerprint.rawValue == "SHA256:\(expected)")
}

@Test(.timeLimit(.minutes(1)))
func registrationRequestEncodesANSWireKeys() throws {
    let host = try ANS::Host(rawValue: "agent.example.com")
    let endpoint = ANS::Endpoint(url: URL(string: "https://agent.example.com/mcp")!, protocolKind: .mcp)
    let request = try ANS::Registration.Request(
        displayName: "Agent",
        host: host,
        endpoints: [endpoint],
        version: try ANS::Version("1.0.0"),
        identityCSR: "csr",
        serverCSR: "server-csr",
        description: "Description"
    )

    let data = try JSONEncoder().encode(request)
    let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

    #expect(object["agentDisplayName"] as? String == "Agent")
    #expect(object["agentHost"] as? String == "agent.example.com")
    #expect(object["identityCsrPEM"] as? String == "csr")
    #expect(object["serverCsrPEM"] as? String == "server-csr")
    #expect(object["agentDescription"] as? String == "Description")
    #expect(object["displayName"] == nil)
    #expect(object["host"] == nil)
}

@Test(.timeLimit(.minutes(1)))
func agentDecodesANSWireKeys() throws {
    let json = """
    {
      "agentId": "agent-1",
      "ansId": "entry-1",
      "ansName": "ans://v1.0.0.agent.example.com",
      "agentHost": "agent.example.com",
      "agentDisplayName": "Agent",
      "agentDescription": "Description",
      "version": "1.0.0",
      "agentStatus": "ACTIVE",
      "endpoints": [
        {
          "agentUrl": "https://agent.example.com/mcp",
          "protocol": "MCP",
          "transports": ["STREAMABLE-HTTP"],
          "metaDataUrl": "https://agent.example.com/.well-known/agent-card.json"
        }
      ]
    }
    """

    let agent = try JSONDecoder().decode(ANS::Agent.self, from: Data(json.utf8))

    #expect(agent.id == ANS::Agent.ID("agent-1"))
    #expect(agent.entryID == ANS::Entry.ID("entry-1"))
    #expect(agent.name?.rawValue == "ans://v1.0.0.agent.example.com")
    #expect(agent.host == (try ANS::Host(rawValue: "agent.example.com")))
    #expect(agent.displayName == "Agent")
    #expect(agent.status == .active)
    #expect(agent.endpoints.first?.url.absoluteString == "https://agent.example.com/mcp")
    #expect(agent.endpoints.first?.protocolKind == .mcp)
}
