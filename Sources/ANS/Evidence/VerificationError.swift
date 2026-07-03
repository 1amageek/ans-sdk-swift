public enum VerificationError: Error, Sendable, Equatable {
    case badgeHostMismatch(expected: Host, actual: Host)
    case badgeStatusRejected(Badge.Status)
    case missingServerFingerprint
    case fingerprintMismatch(expected: Fingerprint, actual: Fingerprint)
}
