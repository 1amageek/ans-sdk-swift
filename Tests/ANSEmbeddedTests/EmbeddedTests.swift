import ANSEmbedded
import Testing

@Test(.timeLimit(.minutes(1)))
func embeddedNameUsesUnqualifiedTypes() throws {
    let name = try Name(rawValue: "ans://v1.0.0.robot.example.com")

    #expect(name.version == (try Version("1.0.0")))
    #expect(name.host == (try Host(rawValue: "robot.example.com")))
}

@Test(.timeLimit(.minutes(1)))
func embeddedVerifierUsesInjectedBadgeProvider() throws {
    let host = try Host(rawValue: "robot.example.com")
    let fingerprint = try Fingerprint(rawValue: "SHA256:00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff")
    let badge = Badge(host: host, status: .active, serverFingerprints: [fingerprint])
    let verifier = Verifier(provider: StaticBadgeProvider(badge: badge))

    let outcome = try verifier.verifyServer(host: host, fingerprint: fingerprint)

    #expect(outcome.isVerified)
}

private struct StaticBadgeProvider: BadgeProviding {
    let badge: Badge

    func badge(for host: Host) throws -> Badge? {
        badge.host == host ? badge : nil
    }
}
