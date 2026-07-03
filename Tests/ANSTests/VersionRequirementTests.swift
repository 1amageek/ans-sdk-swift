import Testing
import ANS

@Suite("VersionRequirement")
struct VersionRequirementTests {
    @Test(.timeLimit(.minutes(1)))
    func matchesExactCaretTildeAndAny() throws {
        let exact = try VersionRequirement("1.2.3")
        let caret = try VersionRequirement("^1.2.3")
        let tilde = try VersionRequirement("~1.2.3")
        let any = try VersionRequirement("*")

        #expect(exact.matches(try Version("1.2.3")))
        #expect(!exact.matches(try Version("1.2.4")))
        #expect(caret.matches(try Version("1.9.0")))
        #expect(!caret.matches(try Version("2.0.0")))
        #expect(tilde.matches(try Version("1.2.9")))
        #expect(!tilde.matches(try Version("1.3.0")))
        #expect(any.matches(try Version("99.0.0")))
    }
}
