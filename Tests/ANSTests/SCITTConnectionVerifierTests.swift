import Testing
import ANS

@Suite("SCITTConnectionVerifier")
struct SCITTConnectionVerifierTests {
    @Test(.timeLimit(.minutes(1)))
    func verifiesStatusTokenOnlyHeaders() async throws {
        let host = try Host(rawValue: "agent.example.com")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let certificate = CertificateIdentity.fromFingerprint(fingerprint, commonName: host.rawValue)
        let token = try connectionToken(host: host, fingerprint: fingerprint)
        let verifier = ConnectionSCITTVerifier(token: token)
        let connectionVerifier = SCITTConnectionVerifier(verifier: verifier)

        let outcome = try await connectionVerifier.verify(
            headers: SCITTHeaders(statusToken: [4, 5, 6]),
            certificate: certificate,
            host: host,
            role: .server
        )

        #expect(outcome == .verified)
        #expect(await verifier.tokenCalls() == 1)
        #expect(await verifier.receiptCalls() == 0)
    }

    @Test(.timeLimit(.minutes(1)))
    func verifiesReceiptWhenItIsPresent() async throws {
        let host = try Host(rawValue: "agent.example.com")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let certificate = CertificateIdentity.fromFingerprint(fingerprint, commonName: host.rawValue)
        let token = try connectionToken(host: host, fingerprint: fingerprint)
        let verifier = ConnectionSCITTVerifier(token: token)
        let connectionVerifier = SCITTConnectionVerifier(verifier: verifier)

        let outcome = try await connectionVerifier.verify(
            headers: SCITTHeaders(receipt: [1, 2, 3], statusToken: [4, 5, 6]),
            certificate: certificate,
            host: host,
            role: .server,
            receiptPolicy: .optional
        )

        #expect(outcome == .verified)
        #expect(await verifier.tokenCalls() == 1)
        #expect(await verifier.receiptCalls() == 1)
    }

    @Test(.timeLimit(.minutes(1)))
    func ignoresReceiptFailureWhenReceiptIsOptional() async throws {
        let host = try Host(rawValue: "agent.example.com")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let certificate = CertificateIdentity.fromFingerprint(fingerprint, commonName: host.rawValue)
        let token = try connectionToken(host: host, fingerprint: fingerprint)
        let verifier = ConnectionSCITTVerifier(token: token, receiptError: .invalidReceipt)
        let connectionVerifier = SCITTConnectionVerifier(verifier: verifier)

        let outcome = try await connectionVerifier.verify(
            headers: SCITTHeaders(receipt: [1, 2, 3], statusToken: [4, 5, 6]),
            certificate: certificate,
            host: host,
            role: .server
        )

        #expect(outcome == .verified)
        #expect(await verifier.tokenCalls() == 1)
        #expect(await verifier.receiptCalls() == 1)
    }

    @Test(.timeLimit(.minutes(1)))
    func rejectsReceiptFailureWhenReceiptIsRequired() async throws {
        let host = try Host(rawValue: "agent.example.com")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let certificate = CertificateIdentity.fromFingerprint(fingerprint, commonName: host.rawValue)
        let token = try connectionToken(host: host, fingerprint: fingerprint)
        let verifier = ConnectionSCITTVerifier(token: token, receiptError: .invalidReceipt)
        let connectionVerifier = SCITTConnectionVerifier(verifier: verifier)

        do {
            _ = try await connectionVerifier.verify(
                headers: SCITTHeaders(receipt: [1, 2, 3], statusToken: [4, 5, 6]),
                certificate: certificate,
                host: host,
                role: .server,
                receiptPolicy: .required
            )
            #expect(Bool(false))
        } catch {
            #expect(error as? ConnectionError == .invalidReceipt)
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func rejectsReceiptOnlyHeaders() async throws {
        let host = try Host(rawValue: "agent.example.com")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let certificate = CertificateIdentity.fromFingerprint(fingerprint, commonName: host.rawValue)
        let token = try connectionToken(host: host, fingerprint: fingerprint)
        let verifier = ConnectionSCITTVerifier(token: token)
        let connectionVerifier = SCITTConnectionVerifier(verifier: verifier)

        do {
            _ = try await connectionVerifier.verify(
                headers: SCITTHeaders(receipt: [1, 2, 3]),
                certificate: certificate,
                host: host,
                role: .server
            )
            #expect(Bool(false))
        } catch {
            #expect(error as? SCITTError == .partialHeaders)
        }
    }
}

private enum ConnectionError: Error, Equatable {
    case invalidReceipt
}

private actor ConnectionSCITTVerifier: SCITTVerifying {
    private let token: VerifiedStatusToken
    private let receiptError: ConnectionError?
    private var receipts = 0
    private var tokens = 0

    init(token: VerifiedStatusToken, receiptError: ConnectionError? = nil) {
        self.token = token
        self.receiptError = receiptError
    }

    func verifyReceipt(_ bytes: [UInt8]) async throws(any Error) -> VerifiedReceipt {
        receipts += 1
        if let receiptError {
            throw receiptError
        }
        return VerifiedReceipt(treeSize: 1, leafIndex: 0, rootHash: [1], eventBytes: bytes)
    }

    func verifyStatusToken(_ bytes: [UInt8]) async throws(any Error) -> VerifiedStatusToken {
        tokens += 1
        return token
    }

    func receiptCalls() -> Int {
        receipts
    }

    func tokenCalls() -> Int {
        tokens
    }
}

private func connectionToken(host: Host, fingerprint: Fingerprint) throws -> VerifiedStatusToken {
    let payload = StatusTokenPayload(
        agentID: Agent.ID(rawValue: "agent-1"),
        name: Name(version: try Version("1.0.0"), host: host),
        status: .active,
        issuedAt: 100,
        expiresAt: 200,
        validServerCertificates: [
            SCITTCertificateEntry(fingerprint: fingerprint, kind: .server),
        ]
    )
    return VerifiedStatusToken(payload: payload, keyID: [1, 2, 3, 4])
}
