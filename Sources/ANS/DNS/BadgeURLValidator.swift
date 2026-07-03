public struct BadgeURLValidator: Sendable, Hashable {
    public let trustedDomains: [Host]

    public init(trustedDomains: [Host] = []) {
        self.trustedDomains = trustedDomains
    }

    public func validate(_ uri: URI) -> Bool {
        guard uri.scheme == "https" else {
            return false
        }
        guard !trustedDomains.isEmpty else {
            return true
        }
        return trustedDomains.contains { trusted in
            uri.host == trusted || uri.host.rawValue.hasSuffix(".\(trusted.rawValue)")
        }
    }
}
