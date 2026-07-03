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
        let uri = try URI(rawValue: "HTTPS://agent.example.com:8443/mcp")

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

    @Test(.timeLimit(.minutes(1)))
    func appendingPercentEncodesQueryItems() throws {
        let uri = try URI(rawValue: "https://registry.ans.godaddy.com/v2")
            .appending(path: "/ans/agents", queryItems: [
                ("cursor", "a b"),
                ("status", "ACTIVE/WARNING"),
                ("skip", nil),
            ])

        #expect(uri.rawValue == "https://registry.ans.godaddy.com/v2/ans/agents?cursor=a%20b&status=ACTIVE%2FWARNING")
    }

    @Test(.timeLimit(.minutes(1)))
    func rejectsInvalidURIShapes() {
        let values = [
            "1https://agent.example.com",
            "+https://agent.example.com",
            "https:/agent.example.com",
            "https://agent.example.com:0",
            "https://agent.example.com:65536",
            "https://user@agent.example.com",
            "https://agent.example.com:abc",
        ]

        for value in values {
            #expect(throws: ParsingError.self) {
                try URI(rawValue: value)
            }
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func constructedURIRequiresValidSchemePortAndPath() throws {
        let host = try Host(rawValue: "agent.example.com")

        #expect((try URI(scheme: "ANS+HTTPS", host: host, path: "/mcp")).rawValue == "ans+https://agent.example.com/mcp")
        #expect(throws: ParsingError.self) {
            try URI(scheme: "1https", host: host)
        }
        #expect(throws: ParsingError.self) {
            try URI(scheme: "https", host: host, port: 0)
        }
        #expect(throws: ParsingError.self) {
            try URI(scheme: "https", host: host, path: "mcp")
        }
    }
}
