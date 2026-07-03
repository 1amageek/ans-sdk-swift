public enum Outcome: Sendable, Hashable {
    case verified
    case notANSAgent
    case degraded(Reason)
    case rejected(Reason)

    public enum Reason: Sendable, Hashable {
        case deprecatedBadge
        case staleCachedBadge
        case verificationUnavailable
        case badgeHostMismatch(expected: Host, actual: Host)
        case badgeStatusRejected(Badge.Status)
        case missingServerFingerprint
        case missingIdentityFingerprint
        case missingCertificateHost
        case missingANSName
        case fingerprintMismatch(expected: Fingerprint, actual: Fingerprint)
        case certificateHostMismatch(expected: Host, actual: Host)
        case ansNameMismatch(expected: Name, actual: Name)
        case daneRequiredButMissing
        case daneMismatch
        case dnsFailure(String)
        case transparencyLogFailure(String)
        case scittFailure(String)
    }
}

extension Outcome {
    var allowsConnection: Bool {
        switch self {
        case .verified, .degraded:
            true
        case .notANSAgent, .rejected:
            false
        }
    }
}
