import Testing
import ANS

@Suite("ClientVerifier")
struct ClientVerifierTests {
    @Test(.timeLimit(.minutes(1)))
    func verifiesClientCertificateAgainstIdentityFingerprintAndANSName() throws {
        let host = try Host(rawValue: "agent.example.com")
        let version = try Version("1.0.0")
        let name = Name(version: version, host: host)
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let certificate = CertificateIdentity(
            commonName: host.rawValue,
            dnsNames: [host.rawValue],
            uriNames: [name.rawValue],
            fingerprint: fingerprint
        )
        let badge = Badge(
            name: name,
            host: host,
            status: .active,
            identityFingerprint: fingerprint
        )

        let outcome = BadgeVerifier().verifyClient(certificate: certificate, badge: badge)

        #expect(outcome == .verified)
    }
}
