import Testing
import ANS

@Suite("Host")
struct HostTests {
    @Test(.timeLimit(.minutes(1)))
    func normalizesHost() throws {
        let host = try Host(rawValue: "Agent.Example.COM.")

        #expect(host.rawValue == "agent.example.com")
    }

    @Test(.timeLimit(.minutes(1)))
    func rejectsIPAddress() throws {
        #expect(throws: ParsingError.self) {
            try Host(rawValue: "192.168.0.1")
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func rejectsBadLabel() throws {
        #expect(throws: ParsingError.self) {
            try Host(rawValue: "-agent.example.com")
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func buildsDiscoveryNames() throws {
        let host = try Host(rawValue: "agent.example.com")

        #expect(host.ansBadgeName == "_ans-badge.agent.example.com")
        #expect(host.raBadgeName == "_ra-badge.agent.example.com")
        #expect(host.tlsaName() == "_443._tcp.agent.example.com")
        #expect(host.tlsaName(port: 8443) == "_8443._tcp.agent.example.com")
    }

    @Test(.timeLimit(.minutes(1)))
    func rejectsInvalidHostShapes() {
        let longLabel = "\(String(repeating: "a", count: 64)).example.com"
        let values = [
            "",
            "localhost",
            "agent..example.com",
            "agent-.example.com",
            "agent_example.com",
            "agent.example.com:443",
            "[2001:db8::1]",
            longLabel,
        ]

        for value in values {
            #expect(throws: ParsingError.self) {
                try Host(rawValue: value)
            }
        }
    }
}
