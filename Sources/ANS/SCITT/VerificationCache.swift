#if !hasFeature(Embedded)
import Crypto
import Synchronization

public final class SCITTVerificationCache: Sendable {
    public struct OutcomeContext: Sendable, Hashable {
        public let certificateFingerprint: Fingerprint
        public let host: Host
        public let role: SCITTConnectionVerifier.Role

        public init(certificateFingerprint: Fingerprint, host: Host, role: SCITTConnectionVerifier.Role) {
            self.certificateFingerprint = certificateFingerprint
            self.host = host
            self.role = role
        }
    }

    public struct Configuration: Sendable, Hashable {
        public static let defaults = Configuration(maxEntries: 1000, receiptTTL: .seconds(86_400))

        public let maxEntries: Int
        public let receiptTTL: Duration

        public init(maxEntries: Int = 1000, receiptTTL: Duration = .seconds(86_400)) {
            self.maxEntries = max(0, maxEntries)
            self.receiptTTL = receiptTTL < .zero ? .zero : receiptTTL
        }
    }

    public struct CachedOutcome: Sendable, Hashable {
        public let outcome: Outcome
        public let token: VerifiedStatusToken
        public let expiresAt: Int64

        public init(outcome: Outcome, token: VerifiedStatusToken, expiresAt: Int64) {
            self.outcome = outcome
            self.token = token
            self.expiresAt = expiresAt
        }
    }

    private struct ReceiptEntry: Sendable {
        let receipt: VerifiedReceipt
        let expiresAt: Int64
    }

    private struct TokenEntry: Sendable {
        let token: VerifiedStatusToken
        let expiresAt: Int64
    }

    private struct OutcomeKey: Sendable, Hashable {
        let context: OutcomeContext
        let tokenHash: [UInt8]
        let receiptHash: [UInt8]?
    }

    private struct OutcomeEntry: Sendable {
        let outcome: CachedOutcome
        let expiresAt: Int64
    }

    private struct State: Sendable {
        var receipts: [[UInt8]: ReceiptEntry] = [:]
        var receiptOrder: [[UInt8]] = []
        var tokens: [[UInt8]: TokenEntry] = [:]
        var tokenOrder: [[UInt8]] = []
        var outcomes: [OutcomeKey: OutcomeEntry] = [:]
        var outcomeOrder: [OutcomeKey] = []
    }

    private let configuration: Configuration
    private let currentUnixTime: @Sendable () -> Int64
    private let state = Mutex(State())

    public var receiptCount: Int {
        state.withLock { $0.receipts.count }
    }

    public var tokenCount: Int {
        state.withLock { $0.tokens.count }
    }

    public var outcomeCount: Int {
        state.withLock { $0.outcomes.count }
    }

    public init(
        configuration: Configuration = .defaults,
        currentUnixTime: @escaping @Sendable () -> Int64 = SCITTClock.unixTime
    ) {
        self.configuration = configuration
        self.currentUnixTime = currentUnixTime
    }

    public func verifiedReceipt(hash: [UInt8]) -> VerifiedReceipt? {
        let now = currentUnixTime()
        return state.withLock { state in
            guard let entry = state.receipts[hash] else {
                return nil
            }
            guard now < entry.expiresAt else {
                removeReceipt(hash, from: &state)
                return nil
            }
            return entry.receipt
        }
    }

    public func insertVerifiedReceipt(_ receipt: VerifiedReceipt, hash: [UInt8]) {
        let now = currentUnixTime()
        state.withLock { state in
            if state.receipts[hash] == nil {
                state.receiptOrder.append(hash)
            }
            state.receipts[hash] = ReceiptEntry(
                receipt: receipt,
                expiresAt: SCITTClock.adding(now, SCITTClock.seconds(from: configuration.receiptTTL))
            )
            evictReceipts(from: &state)
        }
    }

    public func verifiedStatusToken(hash: [UInt8]) -> VerifiedStatusToken? {
        let now = currentUnixTime()
        return state.withLock { state in
            guard let entry = state.tokens[hash] else {
                return nil
            }
            guard now < entry.expiresAt else {
                removeToken(hash, from: &state)
                return nil
            }
            return entry.token
        }
    }

    @discardableResult
    public func insertVerifiedStatusToken(_ token: VerifiedStatusToken, hash: [UInt8]) -> Bool {
        guard let expiresAt = token.payload.expiresAt else {
            return false
        }

        state.withLock { state in
            if state.tokens[hash] == nil {
                state.tokenOrder.append(hash)
            }
            state.tokens[hash] = TokenEntry(token: token, expiresAt: expiresAt)
            evictTokens(from: &state)
        }
        return true
    }

    public func outcome(
        context: OutcomeContext,
        tokenHash: [UInt8],
        receiptHash: [UInt8]?
    ) -> CachedOutcome? {
        let now = currentUnixTime()
        let key = OutcomeKey(context: context, tokenHash: tokenHash, receiptHash: receiptHash)
        return state.withLock { state in
            guard let entry = state.outcomes[key] else {
                return nil
            }
            guard now < entry.expiresAt else {
                removeOutcome(key, from: &state)
                return nil
            }
            return entry.outcome
        }
    }

    @discardableResult
    public func insertOutcome(
        _ outcome: CachedOutcome,
        context: OutcomeContext,
        tokenHash: [UInt8],
        receiptHash: [UInt8]?
    ) -> Bool {
        guard outcome.expiresAt > currentUnixTime() else {
            return false
        }

        let key = OutcomeKey(context: context, tokenHash: tokenHash, receiptHash: receiptHash)
        state.withLock { state in
            if state.outcomes[key] == nil {
                state.outcomeOrder.append(key)
            }
            state.outcomes[key] = OutcomeEntry(outcome: outcome, expiresAt: outcome.expiresAt)
            evictOutcomes(from: &state)
        }
        return true
    }

    public func removeAll() {
        state.withLock { state in
            state.receipts.removeAll()
            state.receiptOrder.removeAll()
            state.tokens.removeAll()
            state.tokenOrder.removeAll()
            state.outcomes.removeAll()
            state.outcomeOrder.removeAll()
        }
    }

    public static func hash(_ bytes: [UInt8]) -> [UInt8] {
        Array(SHA256.hash(data: bytes))
    }

    private func evictReceipts(from state: inout State) {
        guard state.receipts.count > configuration.maxEntries else {
            return
        }
        for _ in 0..<(state.receipts.count - configuration.maxEntries) {
            guard !state.receiptOrder.isEmpty else {
                return
            }
            removeReceipt(state.receiptOrder[0], from: &state)
        }
    }

    private func evictTokens(from state: inout State) {
        guard state.tokens.count > configuration.maxEntries else {
            return
        }
        for _ in 0..<(state.tokens.count - configuration.maxEntries) {
            guard !state.tokenOrder.isEmpty else {
                return
            }
            removeToken(state.tokenOrder[0], from: &state)
        }
    }

    private func evictOutcomes(from state: inout State) {
        guard state.outcomes.count > configuration.maxEntries else {
            return
        }
        for _ in 0..<(state.outcomes.count - configuration.maxEntries) {
            guard !state.outcomeOrder.isEmpty else {
                return
            }
            removeOutcome(state.outcomeOrder[0], from: &state)
        }
    }

    private func removeReceipt(_ hash: [UInt8], from state: inout State) {
        state.receipts.removeValue(forKey: hash)
        state.receiptOrder.removeAll { $0 == hash }
    }

    private func removeToken(_ hash: [UInt8], from state: inout State) {
        state.tokens.removeValue(forKey: hash)
        state.tokenOrder.removeAll { $0 == hash }
    }

    private func removeOutcome(_ key: OutcomeKey, from state: inout State) {
        state.outcomes.removeValue(forKey: key)
        state.outcomeOrder.removeAll { $0 == key }
    }
}
#endif
