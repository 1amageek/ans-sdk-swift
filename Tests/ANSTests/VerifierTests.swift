import Foundation
import Testing
import ANS

@Test(.timeLimit(.minutes(1)))
func serverVerificationUsesBadgeAndFingerprint() async throws {
    let host = try ANS::Host(rawValue: "agent.example.com")
    let certificate = ANS::Certificate(der: Data([1, 2, 3]))
    let fingerprint = ANS::Fingerprint.sha256(der: certificate.der)
    let badge = ANS::Badge(host: host, status: .active, serverFingerprints: [fingerprint])
    let resolver = StaticResolver(txtRecords: ["_ans-badge.agent.example.com": ["https://tl.example.com/v1/agents/agent-1"]])
    let verifier = ANS::Verifier(resolver: resolver, log: StaticLog(badge: badge))

    let outcome = try await verifier.verifyServer(host: host, chain: [certificate])

    #expect(outcome.isVerified)
}

@Test(.timeLimit(.minutes(1)))
func serverVerificationRejectsFingerprintMismatch() async throws {
    let host = try ANS::Host(rawValue: "agent.example.com")
    let certificate = ANS::Certificate(der: Data([1, 2, 3]))
    let other = ANS::Fingerprint.sha256(der: Data([9, 9, 9]))
    let badge = ANS::Badge(host: host, status: .active, serverFingerprints: [other])
    let resolver = StaticResolver(txtRecords: ["_ans-badge.agent.example.com": ["https://tl.example.com/v1/agents/agent-1"]])
    let verifier = ANS::Verifier(resolver: resolver, log: StaticLog(badge: badge))

    let outcome = try await verifier.verifyServer(host: host, chain: [certificate])

    if case .rejected = outcome {
        #expect(true)
    } else {
        Issue.record("Expected rejected outcome")
    }
}

@Test(.timeLimit(.minutes(1)))
func daneRequiredPolicyUsesTLSA() async throws {
    let host = try ANS::Host(rawValue: "agent.example.com")
    let certificate = ANS::Certificate(der: Data([1, 2, 3]))
    let fingerprint = ANS::Fingerprint.sha256(der: certificate.der)
    let badge = ANS::Badge(host: host, status: .active, serverFingerprints: [fingerprint])
    let resolver = StaticResolver(
        txtRecords: ["_ans-badge.agent.example.com": ["https://tl.example.com/v1/agents/agent-1"]],
        tlsaRecords: [
            "_443._tcp.agent.example.com": [
                ANS::TLSA(usage: 3, selector: 0, matchingType: 1, certificateAssociationData: fingerprint.digest, dnssecSecure: true)
            ],
        ]
    )
    let verifier = ANS::Verifier(resolver: resolver, log: StaticLog(badge: badge))

    let outcome = try await verifier.verifyServer(host: host, chain: [certificate], policy: .daneRequired)

    #expect(outcome.isVerified)
}

@Test(.timeLimit(.minutes(1)))
func scittRequiredFailsClosedWithDefaultVerifier() async throws {
    let host = try ANS::Host(rawValue: "agent.example.com")
    let certificate = ANS::Certificate(der: Data([1, 2, 3]))
    let fingerprint = ANS::Fingerprint.sha256(der: certificate.der)
    let badge = ANS::Badge(
        host: host,
        status: .active,
        serverFingerprints: [fingerprint],
        receipt: ANS::Receipt(bytes: Data([1]))
    )
    let resolver = StaticResolver(txtRecords: ["_ans-badge.agent.example.com": ["https://tl.example.com/v1/agents/agent-1"]])
    let verifier = ANS::Verifier(resolver: resolver, log: StaticLog(badge: badge))

    let outcome = try await verifier.verifyServer(host: host, chain: [certificate], policy: .scittRequired)

    if case .rejected = outcome {
        #expect(true)
    } else {
        Issue.record("Expected SCITT required policy to reject without verified SCITT evidence")
    }
}

@Test(.timeLimit(.minutes(1)))
func defaultInspectorFailsClientIdentityExtractionWithoutParsedSANs() async throws {
    let host = try ANS::Host(rawValue: "agent.example.com")
    let badge = ANS::Badge(host: host, status: .active)
    let resolver = StaticResolver(txtRecords: ["_ans-badge.agent.example.com": ["https://tl.example.com/v1/agents/agent-1"]])
    let verifier = ANS::Verifier(resolver: resolver, log: StaticLog(badge: badge))

    await #expect(throws: ANS::CertificateError.self) {
        try await verifier.verifyClient(chain: [ANS::Certificate(der: Data([1, 2, 3]))])
    }
}

private struct StaticResolver: ANS::Resolving {
    let txtRecords: [String: [String]]
    let tlsaRecords: [String: [ANS::TLSA]]

    init(txtRecords: [String: [String]] = [:], tlsaRecords: [String: [ANS::TLSA]] = [:]) {
        self.txtRecords = txtRecords
        self.tlsaRecords = tlsaRecords
    }

    func txt(_ name: String) async throws -> [String] {
        txtRecords[name] ?? []
    }

    func tlsa(_ name: String) async throws -> [ANS::TLSA] {
        tlsaRecords[name] ?? []
    }

    func serviceBinding(_ host: ANS::Host) async throws -> [ANS::ServiceBinding] {
        []
    }
}

private struct StaticLog: ANS::TransparencyLog {
    let badge: ANS::Badge

    func badge(for agent: ANS::Agent.ID) async throws -> ANS::Badge {
        badge
    }

    func badge(at url: URL) async throws -> ANS::Badge {
        badge
    }

    func audit(for agent: ANS::Agent.ID, page: ANS::Page?) async throws -> ANS::Audit {
        ANS::Audit(events: [])
    }

    func receipt(for agent: ANS::Agent.ID) async throws -> ANS::Receipt {
        ANS::Receipt(bytes: Data([1]))
    }

    func statusToken(for agent: ANS::Agent.ID) async throws -> ANS::Token {
        ANS::Token(bytes: Data([1]))
    }

    func checkpoint() async throws -> ANS::Checkpoint {
        ANS::Checkpoint(origin: "test", treeSize: 0, rootHash: Data(), signature: Data())
    }

    func checkpointHistory(page: ANS::Page?) async throws -> [ANS::Checkpoint] {
        []
    }

    func schema(version: String) async throws -> Data {
        Data()
    }

    func rootKeys() async throws -> [ANS::RootKey] {
        []
    }
}
