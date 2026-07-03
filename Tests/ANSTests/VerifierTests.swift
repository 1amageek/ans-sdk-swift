import Testing
import ANS

@Suite("Verifier")
struct VerifierTests {
    @Test(.timeLimit(.minutes(1)))
    func verifiesMatchingBadge() throws {
        let host = try Host(rawValue: "agent.example.com")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let badge = Badge(host: host, status: .active, serverFingerprint: fingerprint)

        let outcome = BadgeVerifier().verifyServer(host: host, fingerprint: fingerprint, badge: badge)

        #expect(outcome == .verified)
    }

    @Test(.timeLimit(.minutes(1)))
    func rejectsMismatchedFingerprint() throws {
        let host = try Host(rawValue: "agent.example.com")
        let expected = try Fingerprint.sha256(bytes: [1, 2, 3])
        let actual = try Fingerprint.sha256(bytes: [4, 5, 6])
        let badge = Badge(host: host, status: .active, serverFingerprint: expected)

        let outcome = BadgeVerifier().verifyServer(host: host, fingerprint: actual, badge: badge)

        #expect(outcome == .rejected(.fingerprintMismatch(expected: expected, actual: actual)))
    }

    @Test(.timeLimit(.minutes(1)))
    func returnsNotANSAgentWhenBadgeIsMissing() throws {
        let host = try Host(rawValue: "agent.example.com")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])

        let outcome = BadgeVerifier().verifyServer(host: host, fingerprint: fingerprint, badge: nil)

        #expect(outcome == .notANSAgent)
    }

    @Test(.timeLimit(.minutes(1)))
    func rejectsMissingServerFingerprint() throws {
        let host = try Host(rawValue: "agent.example.com")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let badge = Badge(host: host, status: .active)

        let outcome = BadgeVerifier().verifyServer(host: host, fingerprint: fingerprint, badge: badge)

        #expect(outcome == .rejected(.missingServerFingerprint))
    }

    @Test(.timeLimit(.minutes(1)))
    func rejectsTerminalBadgeStatuses() throws {
        let host = try Host(rawValue: "agent.example.com")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let verifier = BadgeVerifier()

        for status in [Badge.Status.expired, .revoked] {
            let badge = Badge(host: host, status: status, serverFingerprint: fingerprint)

            #expect(verifier.verifyServer(host: host, fingerprint: fingerprint, badge: badge) == .rejected(.badgeStatusRejected(status)))
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func rejectsCertificateHostMismatch() throws {
        let host = try Host(rawValue: "agent.example.com")
        let certificateHost = try Host(rawValue: "other.example.com")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let badge = Badge(host: host, status: .active, serverFingerprint: fingerprint)
        let certificate = CertificateIdentity.fromFingerprint(fingerprint, commonName: certificateHost.rawValue)

        let outcome = BadgeVerifier().verifyServer(host: host, certificate: certificate, badge: badge)

        #expect(outcome == .rejected(.certificateHostMismatch(expected: host, actual: certificateHost)))
    }

    @Test(.timeLimit(.minutes(1)))
    func rejectsClientWithoutIdentityFingerprint() throws {
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
        let badge = Badge(name: name, host: host, status: .active)

        let outcome = BadgeVerifier().verifyClient(certificate: certificate, badge: badge)

        #expect(outcome == .rejected(.missingIdentityFingerprint))
    }

    @Test(.timeLimit(.minutes(1)))
    func allowsDeprecatedOnlyWhenPolicyAllowsIt() throws {
        let host = try Host(rawValue: "agent.example.com")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let badge = Badge(host: host, status: .deprecated, serverFingerprint: fingerprint)
        let verifier = BadgeVerifier()

        #expect(verifier.verifyServer(host: host, fingerprint: fingerprint, badge: badge) == .rejected(.badgeStatusRejected(.deprecated)))
        #expect(verifier.verifyServer(host: host, fingerprint: fingerprint, badge: badge, policy: .allowDeprecatedBadge) == .degraded(.deprecatedBadge))
    }

    @Test(.timeLimit(.minutes(1)))
    func verifierUsesFreshCacheBeforeProvider() async throws {
        let host = try Host(rawValue: "agent.example.com")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let badge = Badge(host: host, status: .active, serverFingerprint: fingerprint)
        let cache = Cache()
        cache.insert(badge, for: host)
        let provider = RecordingProvider(badge: nil)
        let verifier = Verifier(provider: provider, cache: cache)

        let outcome = try await verifier.verifyServer(host: host, fingerprint: fingerprint)

        #expect(outcome == .verified)
        #expect(await provider.callCount() == 0)
    }

    @Test(.timeLimit(.minutes(1)))
    func verifierRefreshesWhenCachedFingerprintMismatches() async throws {
        let host = try Host(rawValue: "agent.example.com")
        let oldFingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let newFingerprint = try Fingerprint.sha256(bytes: [4, 5, 6])
        let oldBadge = Badge(host: host, status: .active, serverFingerprint: oldFingerprint)
        let newBadge = Badge(host: host, status: .active, serverFingerprint: newFingerprint)
        let cache = Cache()
        cache.insert(oldBadge, for: host)
        let provider = RecordingProvider(badge: newBadge)
        let verifier = Verifier(provider: provider, cache: cache)

        let outcome = try await verifier.verifyServer(host: host, fingerprint: newFingerprint)

        #expect(outcome == .verified)
        #expect(await provider.callCount() == 1)
        #expect(cache.entry(for: host)?.badge == newBadge)
    }

    @Test(.timeLimit(.minutes(1)))
    func verifierUsesStaleCacheWhenFailurePolicyAllowsIt() async throws {
        let host = try Host(rawValue: "agent.example.com")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let badge = Badge(host: host, status: .active, serverFingerprint: fingerprint)
        let configuration = try Cache.Configuration(defaultTTL: .zero)
        let cache = Cache(configuration: configuration)
        cache.insert(badge, for: host)
        let provider = ThrowingProvider()
        let verifier = Verifier(
            provider: provider,
            cache: cache,
            failurePolicy: .failOpenWithCache(maximumStaleness: .seconds(10))
        )

        let outcome = try await verifier.verifyServer(host: host, fingerprint: fingerprint)

        #expect(outcome == .degraded(.staleCachedBadge))
    }

    @Test(.timeLimit(.minutes(1)))
    func requireSCITTRejectsMissingHeaders() async throws {
        let host = try Host(rawValue: "agent.example.com")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let certificate = CertificateIdentity(
            commonName: host.rawValue,
            dnsNames: [host.rawValue],
            uriNames: [],
            fingerprint: fingerprint
        )
        let badge = Badge(host: host, status: .active, serverFingerprint: fingerprint)
        let verifier = Verifier(provider: RecordingProvider(badge: badge))

        do {
            _ = try await verifier.verifyServerWithSCITT(
                host: host,
                certificate: certificate,
                headers: SCITTHeaders(),
                scittPolicy: .requireSCITT
            )
            #expect(Bool(false))
        } catch {
            #expect(error as? SCITTError == .missingHeaders)
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func badgeWithSCITTEnhancementFallsBackWhenHeadersAreAbsent() async throws {
        let host = try Host(rawValue: "agent.example.com")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let certificate = CertificateIdentity(
            commonName: host.rawValue,
            dnsNames: [host.rawValue],
            uriNames: [],
            fingerprint: fingerprint
        )
        let badge = Badge(host: host, status: .active, serverFingerprint: fingerprint)
        let provider = RecordingProvider(badge: badge)
        let verifier = Verifier(provider: provider)

        let outcome = try await verifier.verifyServerWithSCITT(
            host: host,
            certificate: certificate,
            headers: SCITTHeaders(),
            scittPolicy: .badgeWithSCITTEnhancement
        )

        #expect(outcome == .verified)
        #expect(await provider.callCount() == 1)
    }
}

private enum ProviderError: Error {
    case unavailable
}

private actor RecordingProvider: BadgeProviding {
    private let storedBadge: Badge?
    private var calls = 0

    init(badge: Badge?) {
        self.storedBadge = badge
    }

    func badge(for host: Host) async throws(any Error) -> Badge? {
        calls += 1
        return storedBadge
    }

    func callCount() -> Int {
        calls
    }
}

private struct ThrowingProvider: BadgeProviding {
    func badge(for host: Host) async throws(any Error) -> Badge? {
        throw ProviderError.unavailable
    }
}
