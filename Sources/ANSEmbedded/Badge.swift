public struct Badge: Sendable, Hashable {
    public enum Status: String, Sendable, Hashable {
        case active = "ACTIVE"
        case warning = "WARNING"
        case deprecated = "DEPRECATED"
        case expired = "EXPIRED"
        case revoked = "REVOKED"
        case verified = "VERIFIED"

        public var isRejected: Bool {
            self == .expired || self == .revoked
        }
    }

    public let name: Name?
    public let host: Host
    public let status: Status
    public let serverFingerprints: [Fingerprint]
    public let endpoints: [Endpoint]

    public init(
        name: Name? = nil,
        host: Host,
        status: Status,
        serverFingerprints: [Fingerprint] = [],
        endpoints: [Endpoint] = []
    ) {
        self.name = name
        self.host = host
        self.status = status
        self.serverFingerprints = serverFingerprints
        self.endpoints = endpoints
    }
}
