public struct Certificate: Sendable, Hashable {
    public enum Kind: String, Sendable, Hashable {
        case server = "SERVER"
        case identity = "IDENTITY"
    }

    public let pem: String
    public let issuer: String?
    public let subject: String?
    public let serialNumber: String?
    public let validFrom: String?
    public let validTo: String?
    public let csrID: String?
    public let publicKeyAlgorithm: String?
    public let signatureAlgorithm: String?

    public init(
        pem: String,
        issuer: String? = nil,
        subject: String? = nil,
        serialNumber: String? = nil,
        validFrom: String? = nil,
        validTo: String? = nil,
        csrID: String? = nil,
        publicKeyAlgorithm: String? = nil,
        signatureAlgorithm: String? = nil
    ) {
        self.pem = pem
        self.issuer = issuer
        self.subject = subject
        self.serialNumber = serialNumber
        self.validFrom = validFrom
        self.validTo = validTo
        self.csrID = csrID
        self.publicKeyAlgorithm = publicKeyAlgorithm
        self.signatureAlgorithm = signatureAlgorithm
    }
}

#if !hasFeature(Embedded)
extension Certificate.Kind: Codable {}
extension Certificate: Codable {}
#endif
