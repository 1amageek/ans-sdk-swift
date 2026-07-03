import Testing
import ANS

@Suite("Name")
struct NameTests {
    @Test(.timeLimit(.minutes(1)))
    func parsesVersionedName() throws {
        let name = try Name(rawValue: "ans://v1.2.3.agent.example.com")

        #expect(name.version == (try Version(major: 1, minor: 2, patch: 3)))
        #expect(name.host == (try Host(rawValue: "agent.example.com")))
        #expect(name.rawValue == "ans://v1.2.3.agent.example.com")
    }

    @Test(.timeLimit(.minutes(1)))
    func rejectsInvalidScheme() throws {
        #expect(throws: ParsingError.self) {
            try Name(rawValue: "https://v1.2.3.agent.example.com")
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func rejectsInvalidHost() throws {
        #expect(throws: ParsingError.self) {
            try Name(rawValue: "ans://v1.2.3.localhost")
        }
    }
}
