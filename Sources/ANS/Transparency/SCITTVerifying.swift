import Foundation

public protocol SCITTVerifying: Sendable {
    func verify(badge: Badge) async throws -> Bool
}
