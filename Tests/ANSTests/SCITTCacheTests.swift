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

        #expect(cache.insertVerifiedStatusToken(token, hash: tokenHash))
        cache.insertVerifiedReceipt(receipt, hash: receiptHash)
        #expect(cache.insertOutcome(
            SCITTVerificationCache.CachedOutcome(outcome: .verified, token: token, expiresAt: 200),
            fingerprint: fingerprint,
            tokenHash: tokenHash,
            receiptHash: receiptHash
        ))

        #expect(cache.verifiedStatusToken(hash: tokenHash) == token)
        #expect(cache.verifiedReceipt(hash: receiptHash) == receipt)
        #expect(cache.outcome(fingerprint: fingerprint, tokenHash: tokenHash, receiptHash: receiptHash)?.outcome == .verified)

        clock.withLock { $0 = 201 }

        #expect(cache.verifiedStatusToken(hash: tokenHash) == nil)
        #expect(cache.outcome(fingerprint: fingerprint, tokenHash: tokenHash, receiptHash: receiptHash) == nil)
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
