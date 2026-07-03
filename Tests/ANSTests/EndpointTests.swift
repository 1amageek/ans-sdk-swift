import Testing
import ANS

@Suite("Endpoint")
struct EndpointTests {
    @Test(.timeLimit(.minutes(1)))
    func canonicalizesWireAliases() {
        #expect(Endpoint.ProtocolKind(rawValue: "HTTP_API").rawValue == "HTTP-API")
        #expect(Endpoint.TransportKind(rawValue: "STREAMABLE_HTTP").rawValue == "STREAMABLE-HTTP")
        #expect(Endpoint.TransportKind(rawValue: "JSON_RPC").rawValue == "JSON-RPC")
    }

    @Test(.timeLimit(.minutes(1)))
    func parsesURIHostAndPort() throws {
        let uri = try URI(rawValue: "https://agent.example.com:8443/mcp")

        #expect(uri.scheme == "https")
        #expect(uri.host == (try Host(rawValue: "agent.example.com")))
        #expect(uri.port == 8443)
        #expect(uri.path == "/mcp")
    }

    @Test(.timeLimit(.minutes(1)))
    func appendingPreservesBasePathPrefix() throws {
        let uri = try URI(rawValue: "https://registry.ans.godaddy.com/v2")
            .appending(path: "/ans/identities")

        #expect(uri.rawValue == "https://registry.ans.godaddy.com/v2/ans/identities")
    }
}
