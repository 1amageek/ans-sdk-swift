import Foundation

public protocol Caching: Sendable {
    func value(for key: CacheKey) async throws -> CacheValue?
    func store(_ value: CacheValue, for key: CacheKey, expiresAt: Date?) async throws
}
