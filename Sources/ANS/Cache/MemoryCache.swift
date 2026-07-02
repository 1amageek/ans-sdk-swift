import Foundation
import Synchronization

public final class MemoryCache: Caching {
    private struct Entry: Sendable {
        let value: CacheValue
        let expiresAt: Date?

        var isExpired: Bool {
            guard let expiresAt else { return false }
            return Date() >= expiresAt
        }
    }

    private struct State: Sendable {
        var entries: [CacheKey: Entry] = [:]
    }

    private let state = Mutex(State())

    public init() {}

    public func value(for key: CacheKey) async throws -> CacheValue? {
        state.withLock { state in
            guard let entry = state.entries[key] else { return nil }
            if entry.isExpired {
                state.entries.removeValue(forKey: key)
                return nil
            }
            return entry.value
        }
    }

    public func store(_ value: CacheValue, for key: CacheKey, expiresAt: Date?) async throws {
        state.withLock { state in
            state.entries[key] = Entry(value: value, expiresAt: expiresAt)
        }
    }

    public func removeAll() {
        state.withLock { state in
            state.entries.removeAll()
        }
    }
}
