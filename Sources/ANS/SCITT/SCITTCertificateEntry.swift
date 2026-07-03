public struct SCITTCertificateEntry: Sendable, Hashable {
    public enum Kind: String, Sendable, Hashable {
        case server = "x509-dv-server"
        case identity = "x509-ov-client"
        case unknown
    }

    public let fingerprint: Fingerprint
    public let kind: Kind

    public init(fingerprint: Fingerprint, kind: Kind) {
        self.fingerprint = fingerprint
        self.kind = kind
    }
}

#if !hasFeature(Embedded)
extension SCITTCertificateEntry.Kind: Codable {}
extension SCITTCertificateEntry: Codable {}
#endif
