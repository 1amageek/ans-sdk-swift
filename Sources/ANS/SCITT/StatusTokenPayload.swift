public struct StatusTokenPayload: Sendable, Hashable {
    public let agentID: Agent.ID?
    public let name: Name
    public let status: Badge.Status
    public let issuedAt: Int64?
    public let expiresAt: Int64?
    public let validIdentityCertificates: [SCITTCertificateEntry]
    public let validServerCertificates: [SCITTCertificateEntry]
    public let metadataHashes: [String: String]

    public init(
        agentID: Agent.ID? = nil,
        name: Name,
        status: Badge.Status,
        issuedAt: Int64? = nil,
        expiresAt: Int64? = nil,
        validIdentityCertificates: [SCITTCertificateEntry] = [],
        validServerCertificates: [SCITTCertificateEntry] = [],
        metadataHashes: [String: String] = [:]
    ) {
        self.agentID = agentID
        self.name = name
        self.status = status
        self.issuedAt = issuedAt
        self.expiresAt = expiresAt
        self.validIdentityCertificates = validIdentityCertificates
        self.validServerCertificates = validServerCertificates
        self.metadataHashes = metadataHashes
    }

    public func matchesServerCertificate(_ fingerprint: Fingerprint) -> Bool {
        validServerCertificates.contains { $0.fingerprint == fingerprint }
    }

    public func matchesIdentityCertificate(_ fingerprint: Fingerprint) -> Bool {
        validIdentityCertificates.contains { $0.fingerprint == fingerprint }
    }
}

#if !hasFeature(Embedded)
extension StatusTokenPayload: Codable {}
#endif
