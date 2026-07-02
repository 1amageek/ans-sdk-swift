import Foundation

public protocol Resolving: Sendable {
    func txt(_ name: String) async throws -> [String]
    func tlsa(_ name: String) async throws -> [TLSA]
    func serviceBinding(_ host: Host) async throws -> [ServiceBinding]
}
