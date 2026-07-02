import Foundation

public struct EmptyResolver: Resolving {
    public init() {}

    public func txt(_ name: String) async throws -> [String] {
        []
    }

    public func tlsa(_ name: String) async throws -> [TLSA] {
        []
    }

    public func serviceBinding(_ host: Host) async throws -> [ServiceBinding] {
        []
    }
}
