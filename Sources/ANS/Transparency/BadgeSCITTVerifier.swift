import Foundation

public struct BadgeSCITTVerifier: SCITTVerifying {
    public init() {}

    public func verify(badge: Badge) async throws -> Bool {
        false
    }
}
