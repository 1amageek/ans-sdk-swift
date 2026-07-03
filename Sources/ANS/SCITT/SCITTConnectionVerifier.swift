#if !hasFeature(Embedded)
public struct SCITTConnectionVerifier: Sendable {
    public enum Role: Sendable, Hashable {
        case server
        case identity
    }

    private let verifier: any SCITTVerifying
    private let cache: SCITTVerificationCache?

    public init(verifier: any SCITTVerifying, cache: SCITTVerificationCache? = nil) {
        self.verifier = verifier
        self.cache = cache
    }

    public func verify(
        headers: SCITTHeaders,
        certificate: CertificateIdentity,
        host: Host,
        role: Role,
        receiptPolicy: ReceiptPolicy = .optional
    ) async throws(any Error) -> Outcome {
        guard !headers.isEmpty else {
            throw SCITTError.missingHeaders
        }
        guard headers.hasStatusToken else {
            throw SCITTError.partialHeaders
        }

        let tokenHash = SCITTVerificationCache.hash(headers.statusToken)
        let receiptHash = headers.hasReceipt ? SCITTVerificationCache.hash(headers.receipt) : nil
        if let cached = cache?.outcome(
            fingerprint: certificate.fingerprint,
            tokenHash: tokenHash,
            receiptHash: receiptHash
        ) {
            return cached.outcome
        }

        let token: VerifiedStatusToken
        if let cachedToken = cache?.verifiedStatusToken(hash: tokenHash) {
            token = cachedToken
        } else {
            token = try await verifier.verifyStatusToken(headers.statusToken)
            cache?.insertVerifiedStatusToken(token, hash: tokenHash)
        }
        let payload = token.payload

        if let receiptHash, cache?.verifiedReceipt(hash: receiptHash) == nil {
            do {
                let receipt = try await verifier.verifyReceipt(headers.receipt)
                cache?.insertVerifiedReceipt(receipt, hash: receiptHash)
            } catch {
                if receiptPolicy == .required {
                    throw error
                }
            }
        }

        guard payload.status.allowsConnection else {
            throw SCITTError.invalidStatus(payload.status)
        }
        guard payload.name.host == host else {
            throw SCITTError.hostMismatch(expected: host, actual: payload.name.host)
        }

        let matched: Bool
        switch role {
        case .server:
            matched = payload.matchesServerCertificate(certificate.fingerprint)
        case .identity:
            matched = payload.matchesIdentityCertificate(certificate.fingerprint)
        }
        guard matched else {
            throw SCITTError.fingerprintMismatch
        }

        if payload.status == .deprecated {
            let outcome = Outcome.degraded(.deprecatedBadge)
            cacheOutcome(outcome, token: token, certificate: certificate, tokenHash: tokenHash, receiptHash: receiptHash)
            return outcome
        }
        let outcome = Outcome.verified
        cacheOutcome(outcome, token: token, certificate: certificate, tokenHash: tokenHash, receiptHash: receiptHash)
        return outcome
    }

    private func cacheOutcome(
        _ outcome: Outcome,
        token: VerifiedStatusToken,
        certificate: CertificateIdentity,
        tokenHash: [UInt8],
        receiptHash: [UInt8]?
    ) {
        guard let expiresAt = token.payload.expiresAt else {
            return
        }
        cache?.insertOutcome(
            SCITTVerificationCache.CachedOutcome(outcome: outcome, token: token, expiresAt: expiresAt),
            fingerprint: certificate.fingerprint,
            tokenHash: tokenHash,
            receiptHash: receiptHash
        )
    }
}
#endif
