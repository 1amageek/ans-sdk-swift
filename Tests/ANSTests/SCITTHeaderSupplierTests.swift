import Synchronization
import Testing
import ANS

@Suite("SCITTHeaderSupplier")
struct SCITTHeaderSupplierTests {
    @Test(.timeLimit(.minutes(1)))
    func currentHeadersFetchesVerifiesAndEncodesArtifacts() async throws {
        let clock = Mutex(Int64(100))
        let artifacts = StaticArtifacts(receipt: [1, 2, 3], statusToken: [4, 5, 6])
        let verifier = StaticSCITTVerifier(expiresAt: 200)
        let supplier = SCITTHeaderSupplier(
            agentID: Agent.ID(rawValue: "agent-1"),
            artifacts: artifacts,
            verifier: verifier,
            currentUnixTime: { clock.withLock { $0 } }
        )

        let headers = await supplier.currentHeaders()

        #expect(headers.httpHeaders()[SCITTHeaders.receiptHeaderName] == "AQID")
        #expect(headers.httpHeaders()[SCITTHeaders.statusTokenHeaderName] == "BAUG")
        #expect(await artifacts.receiptCalls() == 1)
        #expect(await artifacts.statusTokenCalls() == 1)
        #expect(await verifier.receiptCalls() == 1)
        #expect(await verifier.tokenCalls() == 1)
        #expect(await supplier.healthy())
    }

    @Test(.timeLimit(.minutes(1)))
    func currentHeadersSuppressesExpiredStatusToken() async throws {
        let clock = Mutex(Int64(100))
        let artifacts = StaticArtifacts(receipt: [1, 2, 3], statusToken: [4, 5, 6])
        let verifier = StaticSCITTVerifier(expiresAt: 101)
        let supplier = SCITTHeaderSupplier(
            agentID: Agent.ID(rawValue: "agent-1"),
            artifacts: artifacts,
            verifier: verifier,
            currentUnixTime: { clock.withLock { $0 } }
        )

        _ = await supplier.currentHeaders()
        clock.withLock { $0 = 102 }

        let headers = await supplier.currentHeaders()

        #expect(headers.httpHeaders()[SCITTHeaders.receiptHeaderName] == "AQID")
        #expect(headers.httpHeaders()[SCITTHeaders.statusTokenHeaderName] == nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func currentHeadersKeepsTokenWhenReceiptFetchFails() async throws {
        let clock = Mutex(Int64(100))
        let artifacts = StaticArtifacts(receipt: nil, statusToken: [4, 5, 6])
        let verifier = StaticSCITTVerifier(expiresAt: 200)
        let supplier = SCITTHeaderSupplier(
            agentID: Agent.ID(rawValue: "agent-1"),
            artifacts: artifacts,
            verifier: verifier,
            currentUnixTime: { clock.withLock { $0 } }
        )

        let headers = await supplier.currentHeaders()

        #expect(headers.httpHeaders()[SCITTHeaders.receiptHeaderName] == nil)
        #expect(headers.httpHeaders()[SCITTHeaders.statusTokenHeaderName] == "BAUG")
        #expect(await artifacts.receiptCalls() == 1)
        #expect(await artifacts.statusTokenCalls() == 1)
        #expect(await verifier.receiptCalls() == 0)
        #expect(await verifier.tokenCalls() == 1)
        #expect(!(await supplier.healthy()))
        #expect(await supplier.latestError() != nil)
    }
}

private enum ArtifactError: Error {
    case unavailable
}

private actor StaticArtifacts: SCITTArtifactFetching {
    private let receiptBytes: [UInt8]?
    private let statusTokenBytes: [UInt8]?
    private var receiptCount = 0
    private var statusTokenCount = 0

    init(receipt: [UInt8]?, statusToken: [UInt8]?) {
        self.receiptBytes = receipt
        self.statusTokenBytes = statusToken
    }

    func receipt(agentID: Agent.ID) async throws(any Error) -> [UInt8] {
        receiptCount += 1
        guard let receiptBytes else {
            throw ArtifactError.unavailable
        }
        return receiptBytes
    }

    func statusToken(agentID: Agent.ID) async throws(any Error) -> [UInt8] {
        statusTokenCount += 1
        guard let statusTokenBytes else {
            throw ArtifactError.unavailable
        }
        return statusTokenBytes
    }

    func rootKeys() async throws(any Error) -> [RootKey] {
        []
    }

    func receiptCalls() -> Int {
        receiptCount
    }

    func statusTokenCalls() -> Int {
        statusTokenCount
    }
}

private actor StaticSCITTVerifier: SCITTVerifying {
    private let expiresAt: Int64
    private var receipts = 0
    private var tokens = 0

    init(expiresAt: Int64) {
        self.expiresAt = expiresAt
    }

    func verifyReceipt(_ bytes: [UInt8]) async throws(any Error) -> VerifiedReceipt {
        receipts += 1
        return VerifiedReceipt(treeSize: 1, leafIndex: 0, rootHash: [1], eventBytes: bytes)
    }

    func verifyStatusToken(_ bytes: [UInt8]) async throws(any Error) -> VerifiedStatusToken {
        tokens += 1
        return try verifiedToken(exp: expiresAt)
    }

    func receiptCalls() -> Int {
        receipts
    }

    func tokenCalls() -> Int {
        tokens
    }
}
