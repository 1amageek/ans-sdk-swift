#if !hasFeature(Embedded)
import Synchronization

public final class SCITTReceiptCache: Sendable {
    public struct Configuration: Sendable, Hashable {
        public static let defaults = Configuration(maxEntries: 1000, ttl: .seconds(86_400))

        public let maxEntries: Int
        public let ttl: Duration

        public init(maxEntries: Int = 1000, ttl: Duration = .seconds(86_400)) {
            self.maxEntries = max(0, maxEntries)
            self.ttl = ttl < .zero ? .zero : ttl
        }
    }

    private struct Entry: Sendable {
        let receipt: VerifiedReceipt
        let insertedAt: Int64
        let expiresAt: Int64
    }

    private struct State: Sendable {
        var entries: [Agent.ID: Entry] = [:]
        var insertionOrder: [Agent.ID] = []
    }

    private let configuration: Configuration
    private let currentUnixTime: @Sendable () -> Int64
    private let state = Mutex(State())

    public var count: Int {
        state.withLock { $0.entries.count }
    }

    public init(
        configuration: Configuration = .defaults,
        currentUnixTime: @escaping @Sendable () -> Int64 = SCITTClock.unixTime
    ) {
        self.configuration = configuration
        self.currentUnixTime = currentUnixTime
    }

    public func receipt(for agentID: Agent.ID) -> VerifiedReceipt? {
        let now = currentUnixTime()
        return state.withLock { state in
            guard let entry = state.entries[agentID] else {
                return nil
            }
            guard now < entry.expiresAt else {
                remove(agentID, from: &state)
                return nil
            }
            return entry.receipt
        }
    }

    public func insert(_ receipt: VerifiedReceipt, for agentID: Agent.ID) {
        let now = currentUnixTime()
        state.withLock { state in
            if state.entries[agentID] == nil {
                state.insertionOrder.append(agentID)
            }
            state.entries[agentID] = Entry(
                receipt: receipt,
                insertedAt: now,
                expiresAt: SCITTClock.adding(now, SCITTClock.seconds(from: configuration.ttl))
            )
            evictOverflow(from: &state)
        }
    }

    public func invalidate(agentID: Agent.ID) {
        state.withLock { state in
            remove(agentID, from: &state)
        }
    }

    public func removeAll() {
        state.withLock { state in
            state.entries.removeAll()
            state.insertionOrder.removeAll()
        }
    }

    private func evictOverflow(from state: inout State) {
        guard state.entries.count > configuration.maxEntries else {
            return
        }

        let overflow = state.entries.count - configuration.maxEntries
        for _ in 0..<overflow {
            guard !state.insertionOrder.isEmpty else {
                return
            }
            let oldest = state.insertionOrder.removeFirst()
            state.entries.removeValue(forKey: oldest)
        }
    }

    private func remove(_ agentID: Agent.ID, from state: inout State) {
        state.entries.removeValue(forKey: agentID)
        state.insertionOrder.removeAll { $0 == agentID }
    }
}
#endif
