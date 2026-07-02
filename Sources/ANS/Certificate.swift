import Foundation

public struct Certificate: Sendable, Hashable, Codable {
    public let der: Data
    public let identity: CertificateIdentity?

    public init(der: Data, identity: CertificateIdentity? = nil) {
        self.der = der
        self.identity = identity
    }
}

public struct CertificateIdentity: Sendable, Hashable, Codable {
    public let commonName: String?
    public let dnsNames: [String]
    public let uriNames: [String]
    public let fingerprint: Fingerprint

    public init(commonName: String? = nil, dnsNames: [String] = [], uriNames: [String] = [], fingerprint: Fingerprint) {
        self.commonName = commonName
        self.dnsNames = dnsNames
        self.uriNames = uriNames
        self.fingerprint = fingerprint
    }
}

public protocol CertificateInspecting: Sendable {
    func identity(from certificate: Certificate) throws -> CertificateIdentity
    func fingerprint(of certificate: Certificate) throws -> Fingerprint
}

public struct DefaultCertificateInspector: CertificateInspecting {
    public init() {}

    public func identity(from certificate: Certificate) throws -> CertificateIdentity {
        if let identity = certificate.identity {
            return identity
        }
        return CertificateIdentity(fingerprint: try fingerprint(of: certificate))
    }

    public func fingerprint(of certificate: Certificate) throws -> Fingerprint {
        Fingerprint.sha256(der: certificate.der)
    }
}
