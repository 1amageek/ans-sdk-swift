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
        let context = SCITTVerificationCache.OutcomeContext(
            certificateFingerprint: certificate.fingerprint,
            host: host,
            role: role
        )

        let token: VerifiedStatusToken
        if let cachedToken = cache?.verifiedStatusToken(hash: tokenHash) {
            token = cachedToken
        } else {
            token = try await verifier.verifyStatusToken(headers.statusToken)
            cache?.insertVerifiedStatusToken(token, hash: tokenHash)
        }
        let payload = token.payload

        let outcome = try outcome(for: payload, certificate: certificate, host: host, role: role)
        if receiptPolicy == .optional,
           !headers.hasReceipt,
           let cached = cache?.outcome(context: context, tokenHash: tokenHash, receiptHash: nil) {
            return cached.outcome
        }

        let boundReceiptHash = try await verifiedBoundReceiptHash(
            headers: headers,
            receiptHash: receiptHash,
            receiptPolicy: receiptPolicy
        )
        if let cached = cache?.outcome(context: context, tokenHash: tokenHash, receiptHash: boundReceiptHash) {
            return cached.outcome
        }

        cacheOutcome(outcome, token: token, context: context, tokenHash: tokenHash, receiptHash: nil)
        if let boundReceiptHash {
            cacheOutcome(outcome, token: token, context: context, tokenHash: tokenHash, receiptHash: boundReceiptHash)
        }
        return outcome
    }

    private func outcome(
        for payload: StatusTokenPayload,
        certificate: CertificateIdentity,
        host: Host,
        role: Role
    ) throws(SCITTError) -> Outcome {
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
            return .degraded(.deprecatedBadge)
        }
        return .verified
    }

    private func verifiedBoundReceiptHash(
        headers: SCITTHeaders,
        receiptHash: [UInt8]?,
        receiptPolicy: ReceiptPolicy
    ) async throws(any Error) -> [UInt8]? {
        guard let receiptHash else {
            if receiptPolicy == .required {
                throw SCITTError.partialHeaders
            }
            return nil
        }

        let receipt: VerifiedReceipt
        if let cachedReceipt = cache?.verifiedReceipt(hash: receiptHash) {
            receipt = cachedReceipt
        } else {
            do {
                receipt = try await verifier.verifyReceipt(headers.receipt)
            } catch {
                if receiptPolicy == .required {
                    throw error
                }
                return nil
            }
        }

        guard receipt.eventBytes == headers.statusToken else {
            if receiptPolicy == .required {
                throw SCITTError.invalidToken("SCITT receipt is not bound to status token")
            }
            return nil
        }

        cache?.insertVerifiedReceipt(receipt, hash: receiptHash)
        return receiptHash
    }

    private func cacheOutcome(
        _ outcome: Outcome,
        token: VerifiedStatusToken,
        context: SCITTVerificationCache.OutcomeContext,
        tokenHash: [UInt8],
        receiptHash: [UInt8]?
    ) {
        guard let expiresAt = token.payload.expiresAt else {
            return
        }
        cache?.insertOutcome(
            SCITTVerificationCache.CachedOutcome(outcome: outcome, token: token, expiresAt: expiresAt),
            context: context,
            tokenHash: tokenHash,
            receiptHash: receiptHash
        )
    }
}
#endif
