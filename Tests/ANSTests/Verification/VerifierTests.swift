import Foundation
import Testing
import ANS

@Test(.timeLimit(.minutes(1)))
func serverVerificationUsesBadgeAndFingerprint() async throws {
    let host = try Host(rawValue: "agent.example.com")
    let certificate = Certificate(der: Data([1, 2, 3]))
    let fingerprint = Fingerprint.sha256(der: certificate.der)
    let badge = Badge(host: host, status: .active, serverFingerprints: [fingerprint])
    let resolver = StaticResolver(txtRecords: ["_ans-badge.agent.example.com": ["https://tl.example.com/v1/agents/agent-1"]])
    let verifier = Verifier(resolver: resolver, log: StaticLog(badge: badge))

    let outcome = try await verifier.verifyServer(host: host, chain: [certificate])

    #expect(outcome.isVerified)
}

@Test(.timeLimit(.minutes(1)))
func serverVerificationRejectsFingerprintMismatch() async throws {
    let host = try Host(rawValue: "agent.example.com")
    let certificate = Certificate(der: Data([1, 2, 3]))
    let other = Fingerprint.sha256(der: Data([9, 9, 9]))
    let badge = Badge(host: host, status: .active, serverFingerprints: [other])
    let resolver = StaticResolver(txtRecords: ["_ans-badge.agent.example.com": ["https://tl.example.com/v1/agents/agent-1"]])
    let verifier = Verifier(resolver: resolver, log: StaticLog(badge: badge))

    let outcome = try await verifier.verifyServer(host: host, chain: [certificate])

    if case .rejected = outcome {
        #expect(true)
    } else {
        Issue.record("Expected rejected outcome")
    }
}

@Test(.timeLimit(.minutes(1)))
func daneRequiredPolicyUsesTLSA() async throws {
    let host = try Host(rawValue: "agent.example.com")
    let certificate = Certificate(der: Data([1, 2, 3]))
    let fingerprint = Fingerprint.sha256(der: certificate.der)
    let badge = Badge(host: host, status: .active, serverFingerprints: [fingerprint])
    let resolver = StaticResolver(
        txtRecords: ["_ans-badge.agent.example.com": ["https://tl.example.com/v1/agents/agent-1"]],
        tlsaRecords: [
            "_443._tcp.agent.example.com": [
                TLSA(usage: 3, selector: 0, matchingType: 1, certificateAssociationData: fingerprint.digest, dnssecSecure: true)
            ],
        ]
    )
    let verifier = Verifier(resolver: resolver, log: StaticLog(badge: badge))

    let outcome = try await verifier.verifyServer(host: host, chain: [certificate], policy: .daneRequired)

    #expect(outcome.isVerified)
}

@Test(.timeLimit(.minutes(1)))
func scittRequiredFailsClosedWithDefaultVerifier() async throws {
    let host = try Host(rawValue: "agent.example.com")
    let certificate = Certificate(der: Data([1, 2, 3]))
    let fingerprint = Fingerprint.sha256(der: certificate.der)
    let badge = Badge(
        host: host,
        status: .active,
        serverFingerprints: [fingerprint],
        receipt: Receipt(bytes: Data([1]))
    )
    let resolver = StaticResolver(txtRecords: ["_ans-badge.agent.example.com": ["https://tl.example.com/v1/agents/agent-1"]])
    let verifier = Verifier(resolver: resolver, log: StaticLog(badge: badge))

    let outcome = try await verifier.verifyServer(host: host, chain: [certificate], policy: .scittRequired)

    if case .rejected = outcome {
        #expect(true)
    } else {
        Issue.record("Expected SCITT required policy to reject without verified SCITT evidence")
    }
}

@Test(.timeLimit(.minutes(1)))
func defaultInspectorFailsClientIdentityExtractionWithoutParsedSANs() async throws {
    let host = try Host(rawValue: "agent.example.com")
    let badge = Badge(host: host, status: .active)
    let resolver = StaticResolver(txtRecords: ["_ans-badge.agent.example.com": ["https://tl.example.com/v1/agents/agent-1"]])
    let verifier = Verifier(resolver: resolver, log: StaticLog(badge: badge))

    await #expect(throws: CertificateError.self) {
        try await verifier.verifyClient(chain: [Certificate(der: Data([1, 2, 3]))])
    }
}
