import Foundation

public struct CacheKey: Sendable, Hashable, CustomStringConvertible {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public var description: String { rawValue }
}

public enum CacheValue: Sendable, Hashable {
    case badge(Badge)
    case rootKeys([RootKey])
    case checkpoint(Checkpoint)
    case outcome(Outcome)
    case data(Data)
}

public protocol Caching: Sendable {
    func value(for key: CacheKey) async throws -> CacheValue?
    func store(_ value: CacheValue, for key: CacheKey, expiresAt: Date?) async throws
}

public actor MemoryCache: Caching {
    private struct Entry: Sendable {
        let value: CacheValue
        let expiresAt: Date?

        var isExpired: Bool {
            guard let expiresAt else { return false }
            return Date() >= expiresAt
        }
    }

    private var entries: [CacheKey: Entry] = [:]

    public init() {}

    public func value(for key: CacheKey) async throws -> CacheValue? {
        guard let entry = entries[key] else { return nil }
        if entry.isExpired {
            entries.removeValue(forKey: key)
            return nil
        }
        return entry.value
    }

    public func store(_ value: CacheValue, for key: CacheKey, expiresAt: Date?) async throws {
        entries[key] = Entry(value: value, expiresAt: expiresAt)
    }

    public func removeAll() {
        entries.removeAll()
    }
}
