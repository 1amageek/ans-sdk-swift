import Foundation

public actor Verifier {
    private let resolver: any Resolving
    private let log: any TransparencyLog
    private let inspector: any CertificateInspecting
    private let cache: (any Caching)?
    private let scittVerifier: any SCITTVerifying

    public init(
        resolver: any Resolving,
        log: any TransparencyLog,
        inspector: any CertificateInspecting = DefaultCertificateInspector(),
        cache: (any Caching)? = nil,
        scittVerifier: any SCITTVerifying = BadgeSCITTVerifier()
    ) {
        self.resolver = resolver
        self.log = log
        self.inspector = inspector
        self.cache = cache
        self.scittVerifier = scittVerifier
    }

    public func verifyServer(host: Host, chain: [Certificate], policy: Policy = .default) async throws -> Outcome {
        guard let leaf = chain.first else {
            return .rejected(VerificationError(.emptyCertificateChain))
        }

        let fingerprint = try inspector.fingerprint(of: leaf)
        if policy == .pkiOnly {
            return .verified(Evidence(host: host, fingerprint: fingerprint))
        }

        guard let badge = try await badge(for: host) else {
            return .notANSAgent(host)
        }

        let common = try await evaluateCommonEvidence(
            host: host,
            certificate: leaf,
            fingerprint: fingerprint,
            badge: badge,
            fingerprints: badge.serverFingerprints,
            policy: policy
        )

        switch common {
        case .verified, .degraded:
            return common
        case .notANSAgent, .rejected:
            return common
        }
    }

    public func verifyClient(chain: [Certificate], policy: Policy = .default) async throws -> Outcome {
        guard let leaf = chain.first else {
            return .rejected(VerificationError(.emptyCertificateChain))
        }

        let identity = try inspector.identity(from: leaf)
        guard let uri = identity.uriNames.first(where: { $0.hasPrefix("ans://") }) else {
            return .rejected(VerificationError(.missingIdentityName))
        }

        let name = try Name(rawValue: uri)
        let badge = try await badge(for: name.host)
        guard let badge else {
            return .notANSAgent(name.host)
        }

        return try await evaluateCommonEvidence(
            host: name.host,
            certificate: leaf,
            fingerprint: identity.fingerprint,
            badge: badge,
            fingerprints: badge.identityFingerprints,
            policy: policy
        )
    }

    private func evaluateCommonEvidence(
        host: Host,
        certificate: Certificate,
        fingerprint: Fingerprint,
        badge: Badge,
        fingerprints: [Fingerprint],
        policy: Policy
    ) async throws -> Outcome {
        guard badge.host == host else {
            return .rejected(VerificationError(.hostMismatch(expected: host.rawValue, actual: badge.host.rawValue)))
        }

        guard !badge.status.isRejected else {
            return .rejected(VerificationError(.rejectedStatus(badge.status.rawValue)))
        }

        guard fingerprints.contains(fingerprint) else {
            return .rejected(VerificationError(.fingerprintMismatch))
        }

        let daneVerified = try await verifyDANE(host: host, certificate: certificate, policy: policy)
        if policy.requiresDANE && !daneVerified {
            return .rejected(VerificationError(.daneRequired))
        }

        let scittVerified = try await verifySCITT(badge: badge, policy: policy)
        if policy.requiresSCITT && !scittVerified {
            return .rejected(VerificationError(.scittRequired))
        }

        let evidence = Evidence(host: host, badge: badge, fingerprint: fingerprint, daneVerified: daneVerified, scittVerified: scittVerified)
        if policy == .scittEnhanced && !scittVerified {
            return .degraded(evidence, reason: "SCITT evidence was absent; badge verification succeeded")
        }
        return .verified(evidence)
    }

    private func badge(for host: Host) async throws -> Badge? {
        let key = CacheKey("badge:\(host.rawValue)")
        if let cache, let cached = try await cache.value(for: key), case let .badge(badge) = cached {
            return badge
        }

        guard let url = try await badgeURL(for: host) else {
            return nil
        }

        let badge = try await log.badge(at: url)
        if let cache {
            try await cache.store(.badge(badge), for: key, expiresAt: badge.expiresAt)
        }
        return badge
    }

    private func badgeURL(for host: Host) async throws -> URL? {
        let primaryRecords = try await resolver.txt("_ans-badge.\(host.rawValue)")
        if let url = firstURL(in: primaryRecords) {
            return url
        }

        let fallbackRecords = try await resolver.txt("_ra-badge.\(host.rawValue)")
        return firstURL(in: fallbackRecords)
    }

    private func firstURL(in records: [String]) -> URL? {
        for record in records {
            let cleaned = record.replacingOccurrences(of: "\"", with: " ")
            for token in cleaned.split(whereSeparator: \.isWhitespace) {
                if let url = URL(string: String(token)), url.scheme == "https" || url.scheme == "http" {
                    return url
                }
                if token.contains("=") {
                    let parts = token.split(separator: "=", maxSplits: 1)
                    if parts.count == 2, let url = URL(string: String(parts[1])), url.scheme == "https" || url.scheme == "http" {
                        return url
                    }
                }
            }
        }
        return nil
    }

    private func verifyDANE(host: Host, certificate: Certificate, policy: Policy) async throws -> Bool {
        guard policy == .daneAdvisory || policy == .daneRequired || policy == .daneAndBadge else {
            return false
        }
        let records = try await resolver.tlsa("_443._tcp.\(host.rawValue)")
        let verification = DANE.verify(certificate: certificate, records: records, requireDNSSEC: policy.requiresDANE)
        return verification.matched
    }

    private func verifySCITT(badge: Badge, policy: Policy) async throws -> Bool {
        guard policy == .scittEnhanced || policy == .scittRequired else {
            return false
        }
        return try await scittVerifier.verify(badge: badge)
    }
}
