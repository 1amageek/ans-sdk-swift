public struct BadgeVerifier: Sendable {
    public init() {}

    public func verifyServer(
        host: Host,
        fingerprint: Fingerprint,
        badge: Badge?,
        policy: Policy = .badgeRequired
    ) -> Outcome {
        switch policy {
        case .pkiOnly:
            return .verified
        case .badgeRequired:
            return verifyStrict(host: host, fingerprint: fingerprint, badge: badge)
        case .allowDeprecatedBadge:
            return verifyAllowingDeprecated(host: host, fingerprint: fingerprint, badge: badge)
        }
    }

    public func verifyServer(
        host: Host,
        certificate: CertificateIdentity,
        badge: Badge?,
        policy: Policy = .badgeRequired
    ) -> Outcome {
        let fingerprintOutcome = verifyServer(
            host: host,
            fingerprint: certificate.fingerprint,
            badge: badge,
            policy: policy
        )
        guard fingerprintOutcome.allowsConnection else {
            return fingerprintOutcome
        }

        guard certificate.matches(host: host) else {
            do {
                let certificateHost = try certificate.host()
                return .rejected(.certificateHostMismatch(expected: host, actual: certificateHost))
            } catch {
                return .rejected(.missingCertificateHost)
            }
        }

        return fingerprintOutcome
    }

    public func verifyClient(
        certificate: CertificateIdentity,
        badge: Badge?,
        policy: Policy = .badgeRequired
    ) -> Outcome {
        guard policy != .pkiOnly else {
            return .verified
        }
        guard let badge else {
            return .notANSAgent
        }
        guard badge.status.allowsConnection else {
            return .rejected(.badgeStatusRejected(badge.status))
        }
        guard let expectedFingerprint = badge.identityFingerprint else {
            return .rejected(.missingIdentityFingerprint)
        }
        guard expectedFingerprint == certificate.fingerprint else {
            return .rejected(.fingerprintMismatch(expected: expectedFingerprint, actual: certificate.fingerprint))
        }

        let certificateName: Name
        do {
            certificateName = try certificate.ansName()
        } catch {
            return .rejected(.missingANSName)
        }

        guard let badgeName = badge.name else {
            return .rejected(.missingANSName)
        }
        guard certificateName == badgeName else {
            return .rejected(.ansNameMismatch(expected: badgeName, actual: certificateName))
        }

        if badge.status == .deprecated, policy == .allowDeprecatedBadge {
            return .degraded(.deprecatedBadge)
        }
        if badge.status == .deprecated {
            return .rejected(.badgeStatusRejected(badge.status))
        }
        return .verified
    }

    private func verifyStrict(host: Host, fingerprint: Fingerprint, badge: Badge?) -> Outcome {
        guard let badge else {
            return .notANSAgent
        }

        guard badge.host == host else {
            return .rejected(.badgeHostMismatch(expected: host, actual: badge.host))
        }

        guard badge.status.isAcceptableForStrictVerification else {
            return .rejected(.badgeStatusRejected(badge.status))
        }

        guard let expectedFingerprint = badge.serverFingerprint else {
            return .rejected(.missingServerFingerprint)
        }

        guard expectedFingerprint == fingerprint else {
            return .rejected(.fingerprintMismatch(expected: expectedFingerprint, actual: fingerprint))
        }

        return .verified
    }

    private func verifyAllowingDeprecated(host: Host, fingerprint: Fingerprint, badge: Badge?) -> Outcome {
        let strictOutcome = verifyStrict(host: host, fingerprint: fingerprint, badge: badge)
        guard case .rejected(.badgeStatusRejected(let status)) = strictOutcome, status == .deprecated else {
            return strictOutcome
        }

        guard let badge else {
            return .notANSAgent
        }

        guard let expectedFingerprint = badge.serverFingerprint else {
            return .rejected(.missingServerFingerprint)
        }

        guard expectedFingerprint == fingerprint else {
            return .rejected(.fingerprintMismatch(expected: expectedFingerprint, actual: fingerprint))
        }

        return .degraded(.deprecatedBadge)
    }
}
