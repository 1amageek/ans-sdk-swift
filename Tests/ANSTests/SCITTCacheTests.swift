import Synchronization
import Testing
import ANS

@Suite("SCITTCache")
struct SCITTCacheTests {
    @Test(.timeLimit(.minutes(1)))
    func statusTokenCacheExpiresByTokenExp() throws {
        let clock = Mutex(Int64(100))
        let cache = SCITTStatusTokenCache(currentUnixTime: {
            clock.withLock { $0 }
        })
        let token = try verifiedToken(exp: 101)

        #expect(cache.insert(token, for: Agent.ID(rawValue: "agent-1")))
        #expect(cache.token(for: Agent.ID(rawValue: "agent-1")) == token)

        clock.withLock { $0 = 102 }

        #expect(cache.token(for: Agent.ID(rawValue: "agent-1")) == nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func statusTokenCacheRejectsTokensWithoutExpiration() throws {
        let cache = SCITTStatusTokenCache()
        let token = try verifiedTokenWithoutExpiration()

        #expect(!cache.insert(token, for: Agent.ID(rawValue: "agent-1")))
        #expect(cache.token(for: Agent.ID(rawValue: "agent-1")) == nil)
        #expect(cache.count == 0)
    }

    @Test(.timeLimit(.minutes(1)))
    func statusTokenCacheEvictsInvalidatesAndClears() throws {
        let clock = Mutex(Int64(100))
        let cache = SCITTStatusTokenCache(configuration: .init(maxEntries: 2), currentUnixTime: {
            clock.withLock { $0 }
        })
        let first = Agent.ID(rawValue: "agent-1")
        let second = Agent.ID(rawValue: "agent-2")
        let third = Agent.ID(rawValue: "agent-3")

        #expect(cache.insert(try verifiedToken(exp: 200), for: first))
        #expect(cache.insert(try verifiedToken(exp: 201), for: second))
        #expect(cache.insert(try verifiedToken(exp: 202), for: third))

        #expect(cache.token(for: first) == nil)
        #expect(cache.token(for: second) != nil)
        #expect(cache.token(for: third) != nil)
        #expect(cache.count == 2)

        cache.invalidate(agentID: second)
        #expect(cache.token(for: second) == nil)
        #expect(cache.count == 1)

        cache.removeAll()
        #expect(cache.count == 0)
    }

    @Test(.timeLimit(.minutes(1)))
    func receiptCacheExpiresByTTL() {
        let clock = Mutex(Int64(100))
        let cache = SCITTReceiptCache(configuration: .init(ttl: .seconds(5)), currentUnixTime: {
            clock.withLock { $0 }
        })
        let receipt = VerifiedReceipt(treeSize: 1, leafIndex: 0, rootHash: [1], eventBytes: [2])
        let agentID = Agent.ID(rawValue: "agent-1")

        cache.insert(receipt, for: agentID)
        #expect(cache.receipt(for: agentID) == receipt)

        clock.withLock { $0 = 106 }
        #expect(cache.receipt(for: agentID) == nil)
        #expect(cache.count == 0)
    }

    @Test(.timeLimit(.minutes(1)))
    func receiptCacheEvictsInvalidatesAndClears() {
        let cache = SCITTReceiptCache(configuration: .init(maxEntries: 2))
        let first = Agent.ID(rawValue: "agent-1")
        let second = Agent.ID(rawValue: "agent-2")
        let third = Agent.ID(rawValue: "agent-3")

        cache.insert(VerifiedReceipt(treeSize: 1, leafIndex: 0, rootHash: [1], eventBytes: [1]), for: first)
        cache.insert(VerifiedReceipt(treeSize: 2, leafIndex: 1, rootHash: [2], eventBytes: [2]), for: second)
        cache.insert(VerifiedReceipt(treeSize: 3, leafIndex: 2, rootHash: [3], eventBytes: [3]), for: third)

        #expect(cache.receipt(for: first) == nil)
        #expect(cache.receipt(for: second) != nil)
        #expect(cache.receipt(for: third) != nil)
        #expect(cache.count == 2)

        cache.invalidate(agentID: second)
        #expect(cache.receipt(for: second) == nil)
        #expect(cache.count == 1)

        cache.removeAll()
        #expect(cache.count == 0)
    }

    @Test(.timeLimit(.minutes(1)))
    func verificationCacheStoresLayeredArtifacts() throws {
        let clock = Mutex(Int64(100))
        let cache = SCITTVerificationCache(currentUnixTime: {
            clock.withLock { $0 }
        })
        let token = try verifiedToken(exp: 200)
        let receipt = VerifiedReceipt(treeSize: 1, leafIndex: 0, rootHash: [1], eventBytes: [2])
        let tokenHash = SCITTVerificationCache.hash([1, 2, 3])
        let receiptHash = SCITTVerificationCache.hash([4, 5, 6])
        let fingerprint = try Fingerprint.sha256(bytes: [9])
        let host = try Host(rawValue: "agent.example.com")
        let context = SCITTVerificationCache.OutcomeContext(
            certificateFingerprint: fingerprint,
            host: host,
            role: .server
        )

        #expect(cache.insertVerifiedStatusToken(token, hash: tokenHash))
        cache.insertVerifiedReceipt(receipt, hash: receiptHash)
        #expect(cache.insertOutcome(
            SCITTVerificationCache.CachedOutcome(outcome: .verified, token: token, expiresAt: 200),
            context: context,
            tokenHash: tokenHash,
            receiptHash: receiptHash
        ))

        #expect(cache.verifiedStatusToken(hash: tokenHash) == token)
        #expect(cache.verifiedReceipt(hash: receiptHash) == receipt)
        #expect(cache.outcome(context: context, tokenHash: tokenHash, receiptHash: receiptHash)?.outcome == .verified)
        #expect(cache.outcome(
            context: .init(certificateFingerprint: fingerprint, host: host, role: .identity),
            tokenHash: tokenHash,
            receiptHash: receiptHash
        ) == nil)

        clock.withLock { $0 = 201 }

        #expect(cache.verifiedStatusToken(hash: tokenHash) == nil)
        #expect(cache.outcome(context: context, tokenHash: tokenHash, receiptHash: receiptHash) == nil)
    }
}

func verifiedToken(exp: Int64) throws -> VerifiedStatusToken {
    let host = try Host(rawValue: "agent.example.com")
    let version = try Version("1.0.0")
    let name = Name(version: version, host: host)
    let payload = StatusTokenPayload(
        agentID: Agent.ID(rawValue: "agent-1"),
        name: name,
        status: .active,
        issuedAt: 100,
        expiresAt: exp
    )
    return VerifiedStatusToken(payload: payload, keyID: [1, 2, 3, 4])
}

func verifiedTokenWithoutExpiration() throws -> VerifiedStatusToken {
    let host = try Host(rawValue: "agent.example.com")
    let version = try Version("1.0.0")
    let name = Name(version: version, host: host)
    let payload = StatusTokenPayload(
        agentID: Agent.ID(rawValue: "agent-1"),
        name: name,
        status: .active,
        issuedAt: 100
    )
    return VerifiedStatusToken(payload: payload, keyID: [1, 2, 3, 4])
}
