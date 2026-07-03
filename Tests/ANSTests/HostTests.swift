import Testing
import ANS

@Suite("Host")
struct HostTests {
    @Test(.timeLimit(.minutes(1)))
    func normalizesHost() throws {
        let host = try Host(rawValue: "Agent.Example.COM")

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
}
