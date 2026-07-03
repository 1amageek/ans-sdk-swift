import Testing
import ANS

@Suite("Registration")
struct RegistrationTests {
    @Test(.timeLimit(.minutes(1)))
    func validatesEndpointHost() throws {
        let host = try Host(rawValue: "agent.example.com")
        let endpoint = Endpoint(
            url: try URI(rawValue: "https://other.example.com/mcp"),
            protocolKind: .mcp,
            transports: [.streamableHTTP]
        )

        #expect(throws: ValidationError.self) {
            try Registration.Request(displayName: "Agent", host: host, endpoints: [endpoint], version: try Version("1.0.0"))
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func acceptsValidRequest() throws {
        let host = try Host(rawValue: "agent.example.com")
        let endpoint = Endpoint(
            url: try URI(rawValue: "https://agent.example.com/mcp"),
            protocolKind: .mcp,
            transports: [.streamableHTTP]
        )

        let request = try Registration.Request(displayName: "Agent", host: host, endpoints: [endpoint], version: try Version("1.0.0"))

        #expect(request.host == host)
        #expect(request.endpoints.count == 1)
        #expect(request.identityCSRPEM == nil)
        #expect(request.version == (try Version("1.0.0")))
    }
}
