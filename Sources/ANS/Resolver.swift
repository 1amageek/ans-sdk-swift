import Foundation

public struct TLSA: Sendable, Hashable, Codable {
    public let usage: Int
    public let selector: Int
    public let matchingType: Int
    public let certificateAssociationData: Data
    public let dnssecSecure: Bool

    public init(usage: Int, selector: Int, matchingType: Int, certificateAssociationData: Data, dnssecSecure: Bool) {
        self.usage = usage
        self.selector = selector
        self.matchingType = matchingType
        self.certificateAssociationData = certificateAssociationData
        self.dnssecSecure = dnssecSecure
    }
}

public struct ServiceBinding: Sendable, Hashable, Codable {
    public let priority: Int
    public let target: String
    public let parameters: [String: String]

    public init(priority: Int, target: String, parameters: [String: String] = [:]) {
        self.priority = priority
        self.target = target
        self.parameters = parameters
    }
}

public protocol Resolving: Sendable {
    func txt(_ name: String) async throws -> [String]
    func tlsa(_ name: String) async throws -> [TLSA]
    func serviceBinding(_ host: Host) async throws -> [ServiceBinding]
}

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
