import Testing
import ANS

@Suite("Version")
struct VersionTests {
    @Test(.timeLimit(.minutes(1)))
    func parsesOptionalPrefixAndCanonicalizes() throws {
        let lower = try Version("v1.2.3")
        let upper = try Version("V2.0.1")

        #expect(lower.rawValue == "1.2.3")
        #expect(upper == (try Version(major: 2, minor: 0, patch: 1)))
    }

    @Test(.timeLimit(.minutes(1)))
    func ordersByMajorMinorPatch() throws {
        let versions = [
            try Version("1.0.1"),
            try Version("2.0.0"),
            try Version("1.1.0"),
            try Version("1.0.0"),
        ]

        #expect(versions.sorted().map(\.rawValue) == ["1.0.0", "1.0.1", "1.1.0", "2.0.0"])
    }

    @Test(.timeLimit(.minutes(1)))
    func rejectsMalformedStrings() {
        let values = [
            "",
            "v",
            "1",
            "1.2",
            "1.2.3.4",
            "1..3",
            "01.2.3",
            "1.02.3",
            "1.2.03",
            "1.2.x",
            " 1.2.3",
            "1.2.3 ",
        ]

        for value in values {
            #expect(throws: ParsingError.self) {
                try Version(value)
            }
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func rejectsNegativeComponents() {
        #expect(throws: ParsingError.self) {
            try Version(major: -1, minor: 0, patch: 0)
        }
        #expect(throws: ParsingError.self) {
            try Version(major: 0, minor: -1, patch: 0)
        }
        #expect(throws: ParsingError.self) {
            try Version(major: 0, minor: 0, patch: -1)
        }
    }
}
