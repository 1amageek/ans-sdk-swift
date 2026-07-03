#if !hasFeature(Embedded)
public actor Verifier {
    private let provider: any BadgeProviding
    private let badgeVerifier: BadgeVerifier
    private let cache: (any Caching)?
    private let failurePolicy: FailurePolicy
    private let dnsResolver: (any DNSResolving)?
    private let danePolicy: DANEPolicy
    private let scittConnectionVerifier: SCITTConnectionVerifier?

    public init(
        provider: any BadgeProviding,
        badgeVerifier: BadgeVerifier = BadgeVerifier(),
        cache: (any Caching)? = nil,
        failurePolicy: FailurePolicy = .failClosed,
        dnsResolver: (any DNSResolving)? = nil,
        danePolicy: DANEPolicy = .disabled,
        scittConnectionVerifier: SCITTConnectionVerifier? = nil
    ) {
        self.provider = provider
        self.badgeVerifier = badgeVerifier
        self.cache = cache
        self.failurePolicy = failurePolicy
        self.dnsResolver = dnsResolver
        self.danePolicy = danePolicy
        self.scittConnectionVerifier = scittConnectionVerifier
    }

    public func verifyServer(
        host: Host,
        fingerprint: Fingerprint,
        policy: Policy = .badgeRequired
    ) async throws(any Error) -> Outcome {
        if let cachedOutcome = verifyFreshCache(host: host, fingerprint: fingerprint, policy: policy) {
            return cachedOutcome
        }

        do {
            let badge = try await provider.badge(for: host)
            guard let badge else {
                return .notANSAgent
            }
            cache?.insert(badge, for: host)
            return badgeVerifier.verifyServer(host: host, fingerprint: fingerprint, badge: badge, policy: policy)
        } catch {
            return try applyFailurePolicy(host: host, fingerprint: fingerprint, policy: policy, cause: error)
        }
    }

    public func verifyServer(
        host: Host,
        certificate: CertificateIdentity,
        policy: Policy = .badgeRequired
    ) async throws(any Error) -> Outcome {
        if let cachedOutcome = verifyFreshServerCertificateCache(host: host, certificate: certificate, policy: policy) {
            return try await applyDANE(host: host, certificate: certificate, current: cachedOutcome)
        }

        do {
            let badge = try await provider.badge(for: host)
            guard let badge else {
                return .notANSAgent
            }
            cache?.insert(badge, for: host)
            let outcome = badgeVerifier.verifyServer(host: host, certificate: certificate, badge: badge, policy: policy)
            guard outcome.allowsConnection else {
                return outcome
            }
            return try await applyDANE(host: host, certificate: certificate, current: outcome)
        } catch {
            let outcome = try applyServerCertificateFailurePolicy(
                host: host,
                certificate: certificate,
                policy: policy,
                cause: error
            )
            guard outcome.allowsConnection else {
                return outcome
            }
            return try await applyDANE(host: host, certificate: certificate, current: outcome)
        }
    }

    public func verifyClient(
        certificate: CertificateIdentity,
        policy: Policy = .badgeRequired
    ) async throws(any Error) -> Outcome {
        let host: Host
        let name: Name
        do {
            host = try certificate.host()
            name = try certificate.ansName()
        } catch {
            return .rejected(.missingANSName)
        }

        if let cachedOutcome = verifyFreshClientCache(host: host, version: name.version, certificate: certificate, policy: policy) {
            return try await applyDANE(host: host, certificate: certificate, current: cachedOutcome)
        }

        do {
            let badge: Badge?
            if let versionedProvider = provider as? any VersionedBadgeProviding {
                badge = try await versionedProvider.badge(for: host, version: name.version)
            } else {
                badge = try await provider.badge(for: host)
            }
            guard let badge else {
                return .notANSAgent
            }
            cache?.insert(badge, for: host, version: name.version)
            let outcome = badgeVerifier.verifyClient(certificate: certificate, badge: badge, policy: policy)
            guard outcome.allowsConnection else {
                return outcome
            }
            return try await applyDANE(host: host, certificate: certificate, current: outcome)
        } catch {
            return try applyClientFailurePolicy(host: host, version: name.version, certificate: certificate, policy: policy, cause: error)
        }
    }

    public func verifyServerWithSCITT(
        host: Host,
        certificate: CertificateIdentity,
        headers: SCITTHeaders,
        policy: Policy = .badgeRequired,
        scittPolicy: SCITTPolicy = .withBadgeFallback
    ) async throws(any Error) -> Outcome {
        if scittPolicy == .badgeWithSCITTEnhancement {
            let badgeOutcome = try await verifyServer(host: host, certificate: certificate, policy: policy)
            guard badgeOutcome.allowsConnection, !headers.isEmpty else {
                return badgeOutcome
            }
        }

        guard !headers.isEmpty else {
            if scittPolicy == .requireSCITT {
                throw SCITTError.missingHeaders
            }
            return try await verifyServer(host: host, certificate: certificate, policy: policy)
        }
        guard let scittConnectionVerifier else {
            throw SCITTError.invalidToken("SCITT headers are present but no SCITT verifier is configured")
        }
        let outcome = try await scittConnectionVerifier.verify(
            headers: headers,
            certificate: certificate,
            host: host,
            role: .server,
            receiptPolicy: scittPolicy.receiptPolicy
        )
        guard outcome.allowsConnection else {
            return outcome
        }
        return try await applyDANE(host: host, certificate: certificate, current: outcome)
    }

    public func verifyClientWithSCITT(
        certificate: CertificateIdentity,
        headers: SCITTHeaders,
        policy: Policy = .badgeRequired,
        scittPolicy: SCITTPolicy = .withBadgeFallback
    ) async throws(any Error) -> Outcome {
        if scittPolicy == .badgeWithSCITTEnhancement {
            let badgeOutcome = try await verifyClient(certificate: certificate, policy: policy)
            guard badgeOutcome.allowsConnection, !headers.isEmpty else {
                return badgeOutcome
            }
        }

        guard !headers.isEmpty else {
            if scittPolicy == .requireSCITT {
                throw SCITTError.missingHeaders
            }
            return try await verifyClient(certificate: certificate, policy: policy)
        }
        guard let scittConnectionVerifier else {
            throw SCITTError.invalidToken("SCITT headers are present but no SCITT verifier is configured")
        }
        let host: Host
        do {
            host = try certificate.host()
        } catch {
            return .rejected(.missingCertificateHost)
        }
        let outcome = try await scittConnectionVerifier.verify(
            headers: headers,
            certificate: certificate,
            host: host,
            role: .identity,
            receiptPolicy: scittPolicy.receiptPolicy
        )
        guard outcome.allowsConnection else {
            return outcome
        }
        return try await applyDANE(host: host, certificate: certificate, current: outcome)
    }

    @discardableResult
    public func prefetch(host: Host) async throws(any Error) -> Badge? {
        if let cached = cache?.entry(for: host) {
            return cached.badge
        }

        let badge = try await provider.badge(for: host)
        if let badge {
            cache?.insert(badge, for: host)
        }
        return badge
    }

    public func invalidateCache(for host: Host) {
        cache?.invalidate(host: host)
    }

    private func verifyFreshCache(host: Host, fingerprint: Fingerprint, policy: Policy) -> Outcome? {
        guard let cache else {
            return nil
        }

        for entry in cache.entries(for: host) {
            let outcome = badgeVerifier.verifyServer(
                host: host,
                fingerprint: fingerprint,
                badge: entry.badge,
                policy: policy
            )
            if outcome.allowsConnection {
                return outcome
            }
        }

        return nil
    }

    private func verifyFreshClientCache(
        host: Host,
        version: Version,
        certificate: CertificateIdentity,
        policy: Policy
    ) -> Outcome? {
        guard let cache else {
            return nil
        }
        guard let entry = cache.entry(for: host, version: version) else {
            return nil
        }
        let outcome = badgeVerifier.verifyClient(certificate: certificate, badge: entry.badge, policy: policy)
        if outcome.allowsConnection {
            return outcome
        }
        return nil
    }

    private func verifyFreshServerCertificateCache(
        host: Host,
        certificate: CertificateIdentity,
        policy: Policy
    ) -> Outcome? {
        guard let cache else {
            return nil
        }
        for entry in cache.entries(for: host) {
            let outcome = badgeVerifier.verifyServer(
                host: host,
                certificate: certificate,
                badge: entry.badge,
                policy: policy
            )
            if outcome.allowsConnection {
                return outcome
            }
        }
        return nil
    }

    private func applyFailurePolicy(
        host: Host,
        fingerprint: Fingerprint,
        policy: Policy,
        cause: any Error
    ) throws(any Error) -> Outcome {
        switch failurePolicy {
        case .failClosed:
            throw cause
        case .failOpen:
            return .degraded(.verificationUnavailable)
        case .failOpenWithCache(let maximumStaleness):
            guard let outcome = verifyStaleCache(
                host: host,
                fingerprint: fingerprint,
                policy: policy,
                maximumStaleness: maximumStaleness
            ) else {
                throw cause
            }
            return outcome
        }
    }

    private func applyClientFailurePolicy(
        host: Host,
        version: Version,
        certificate: CertificateIdentity,
        policy: Policy,
        cause: any Error
    ) throws(any Error) -> Outcome {
        switch failurePolicy {
        case .failClosed:
            throw cause
        case .failOpen:
            return .degraded(.verificationUnavailable)
        case .failOpenWithCache(let maximumStaleness):
            guard let cache else {
                throw cause
            }
            guard let entry = cache.staleEntry(for: host, version: version, maximumStaleness: maximumStaleness) else {
                throw cause
            }
            let outcome = badgeVerifier.verifyClient(certificate: certificate, badge: entry.badge, policy: policy)
            if outcome.allowsConnection {
                return .degraded(.staleCachedBadge)
            }
            throw cause
        }
    }

    private func applyServerCertificateFailurePolicy(
        host: Host,
        certificate: CertificateIdentity,
        policy: Policy,
        cause: any Error
    ) throws(any Error) -> Outcome {
        switch failurePolicy {
        case .failClosed:
            throw cause
        case .failOpen:
            return .degraded(.verificationUnavailable)
        case .failOpenWithCache(let maximumStaleness):
            guard let cache else {
                throw cause
            }
            for entry in cache.staleEntries(for: host, maximumStaleness: maximumStaleness) {
                let outcome = badgeVerifier.verifyServer(
                    host: host,
                    certificate: certificate,
                    badge: entry.badge,
                    policy: policy
                )
                if outcome.allowsConnection {
                    return .degraded(.staleCachedBadge)
                }
            }
            throw cause
        }
    }

    private func verifyStaleCache(
        host: Host,
        fingerprint: Fingerprint,
        policy: Policy,
        maximumStaleness: Duration
    ) -> Outcome? {
        guard let cache else {
            return nil
        }

        for entry in cache.staleEntries(for: host, maximumStaleness: maximumStaleness) {
            let outcome = badgeVerifier.verifyServer(
                host: host,
                fingerprint: fingerprint,
                badge: entry.badge,
                policy: policy
            )
            if outcome.allowsConnection {
                return .degraded(.staleCachedBadge)
            }
        }

        return nil
    }

    private func applyDANE(host: Host, certificate: CertificateIdentity, current: Outcome) async throws(any Error) -> Outcome {
        guard danePolicy.shouldVerify else {
            return current
        }
        guard let dnsResolver else {
            return danePolicy.isRequired ? .rejected(.daneRequiredButMissing) : current
        }

        do {
            let records: [TLSARecord]
            switch try await dnsResolver.lookupTLSARecords(for: host, port: 443) {
            case .found(let found):
                records = found
            case .notFound:
                records = []
            }
            let result = DANE.verify(certificate: certificate, records: records, policy: danePolicy)
            guard result.isAcceptable(for: danePolicy) else {
                switch result {
                case .noRecords:
                    return .rejected(.daneRequiredButMissing)
                case .dnssecFailed:
                    return .rejected(.dnsFailure("DNSSEC validation failed"))
                default:
                    return .rejected(.daneMismatch)
                }
            }
            return current
        } catch {
            if danePolicy.isRequired {
                return .rejected(.dnsFailure("\(error)"))
            }
            return current
        }
    }
}
#endif
