import Testing
import ANS

@Suite("SCITTConnectionVerifier")
struct SCITTConnectionVerifierTests {
    private let statusTokenBytes: [UInt8] = [4, 5, 6]

    @Test(.timeLimit(.minutes(1)))
    func verifiesStatusTokenOnlyHeaders() async throws {
        let host = try Host(rawValue: "agent.example.com")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let certificate = CertificateIdentity.fromFingerprint(fingerprint, commonName: host.rawValue)
        let token = try connectionToken(host: host, fingerprint: fingerprint)
        let verifier = ConnectionSCITTVerifier(token: token)
        let connectionVerifier = SCITTConnectionVerifier(verifier: verifier)

        let outcome = try await connectionVerifier.verify(
            headers: SCITTHeaders(statusToken: statusTokenBytes),
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
            headers: SCITTHeaders(receipt: [1, 2, 3], statusToken: statusTokenBytes),
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
            headers: SCITTHeaders(receipt: [1, 2, 3], statusToken: statusTokenBytes),
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
                headers: SCITTHeaders(receipt: [1, 2, 3], statusToken: statusTokenBytes),
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
    func rejectsMissingReceiptWhenReceiptIsRequired() async throws {
        let host = try Host(rawValue: "agent.example.com")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let certificate = CertificateIdentity.fromFingerprint(fingerprint, commonName: host.rawValue)
        let token = try connectionToken(host: host, fingerprint: fingerprint)
        let verifier = ConnectionSCITTVerifier(token: token)
        let connectionVerifier = SCITTConnectionVerifier(verifier: verifier)

        do {
            _ = try await connectionVerifier.verify(
                headers: SCITTHeaders(statusToken: statusTokenBytes),
                certificate: certificate,
                host: host,
                role: .server,
                receiptPolicy: .required
            )
            #expect(Bool(false))
        } catch {
            #expect(error as? SCITTError == .partialHeaders)
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func rejectsRequiredReceiptThatIsNotBoundToStatusToken() async throws {
        let host = try Host(rawValue: "agent.example.com")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let certificate = CertificateIdentity.fromFingerprint(fingerprint, commonName: host.rawValue)
        let token = try connectionToken(host: host, fingerprint: fingerprint)
        let receipt = VerifiedReceipt(treeSize: 1, leafIndex: 0, rootHash: [1], eventBytes: [9, 9, 9])
        let verifier = ConnectionSCITTVerifier(token: token, receipt: receipt)
        let connectionVerifier = SCITTConnectionVerifier(verifier: verifier)

        do {
            _ = try await connectionVerifier.verify(
                headers: SCITTHeaders(receipt: [1, 2, 3], statusToken: statusTokenBytes),
                certificate: certificate,
                host: host,
                role: .server,
                receiptPolicy: .required
            )
            #expect(Bool(false))
        } catch let error as SCITTError {
            #expect(error == .invalidToken("SCITT receipt is not bound to status token"))
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func optionalReceiptFailureDoesNotSatisfyRequiredReceiptCache() async throws {
        let host = try Host(rawValue: "agent.example.com")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let certificate = CertificateIdentity.fromFingerprint(fingerprint, commonName: host.rawValue)
        let token = try connectionToken(host: host, fingerprint: fingerprint)
        let verifier = ConnectionSCITTVerifier(token: token, receiptError: .invalidReceipt)
        let cache = SCITTVerificationCache()
        let connectionVerifier = SCITTConnectionVerifier(verifier: verifier, cache: cache)
        let headers = SCITTHeaders(receipt: [1, 2, 3], statusToken: statusTokenBytes)

        let optionalOutcome = try await connectionVerifier.verify(
            headers: headers,
            certificate: certificate,
            host: host,
            role: .server,
            receiptPolicy: .optional
        )

        #expect(optionalOutcome == .verified)
        do {
            _ = try await connectionVerifier.verify(
                headers: headers,
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
    func outcomeCacheDoesNotBypassHostBinding() async throws {
        let host = try Host(rawValue: "agent.example.com")
        let otherHost = try Host(rawValue: "other.example.com")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let certificate = CertificateIdentity.fromFingerprint(fingerprint, commonName: host.rawValue)
        let token = try connectionToken(host: host, fingerprint: fingerprint)
        let verifier = ConnectionSCITTVerifier(token: token)
        let cache = SCITTVerificationCache()
        let connectionVerifier = SCITTConnectionVerifier(verifier: verifier, cache: cache)

        let outcome = try await connectionVerifier.verify(
            headers: SCITTHeaders(statusToken: statusTokenBytes),
            certificate: certificate,
            host: host,
            role: .server
        )

        #expect(outcome == .verified)
        do {
            _ = try await connectionVerifier.verify(
                headers: SCITTHeaders(statusToken: statusTokenBytes),
                certificate: certificate,
                host: otherHost,
                role: .server
            )
            #expect(Bool(false))
        } catch let error as SCITTError {
            #expect(error == .hostMismatch(expected: otherHost, actual: host))
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func outcomeCacheDoesNotBypassRoleBinding() async throws {
        let host = try Host(rawValue: "agent.example.com")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let certificate = CertificateIdentity.fromFingerprint(fingerprint, commonName: host.rawValue)
        let token = try connectionToken(host: host, fingerprint: fingerprint)
        let verifier = ConnectionSCITTVerifier(token: token)
        let cache = SCITTVerificationCache()
        let connectionVerifier = SCITTConnectionVerifier(verifier: verifier, cache: cache)

        let outcome = try await connectionVerifier.verify(
            headers: SCITTHeaders(statusToken: statusTokenBytes),
            certificate: certificate,
            host: host,
            role: .server
        )

        #expect(outcome == .verified)
        do {
            _ = try await connectionVerifier.verify(
                headers: SCITTHeaders(statusToken: statusTokenBytes),
                certificate: certificate,
                host: host,
                role: .identity
            )
            #expect(Bool(false))
        } catch let error as SCITTError {
            #expect(error == .fingerprintMismatch)
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
    private let receipt: VerifiedReceipt
    private let receiptError: ConnectionError?
    private var receipts = 0
    private var tokens = 0

    init(
        token: VerifiedStatusToken,
        receipt: VerifiedReceipt = VerifiedReceipt(treeSize: 1, leafIndex: 0, rootHash: [1], eventBytes: [4, 5, 6]),
        receiptError: ConnectionError? = nil
    ) {
        self.token = token
        self.receipt = receipt
        self.receiptError = receiptError
    }

    func verifyReceipt(_ bytes: [UInt8]) async throws(any Error) -> VerifiedReceipt {
        receipts += 1
        if let receiptError {
            throw receiptError
        }
        return receipt
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
