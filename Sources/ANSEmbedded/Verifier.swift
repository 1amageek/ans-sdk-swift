public struct Verifier<Provider: BadgeProviding>: Sendable {
    private let provider: Provider

    public init(provider: Provider) {
        self.provider = provider
    }

    public func verifyServer(host: Host, fingerprint: Fingerprint) throws -> Outcome {
        guard let badge = try provider.badge(for: host) else {
            return .notANSAgent(host)
        }
        guard badge.host == host else {
            return .rejected(VerificationError("Badge host does not match server host"))
        }
        guard !badge.status.isRejected else {
            return .rejected(VerificationError("Badge status is rejected"))
        }
        guard badge.serverFingerprints.contains(fingerprint) else {
            return .rejected(VerificationError("Server fingerprint does not match badge"))
        }
        return .verified
    }
}
