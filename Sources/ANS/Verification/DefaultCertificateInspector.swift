import Foundation

public struct DefaultCertificateInspector: CertificateInspecting {
    public init() {}

    public func identity(from certificate: Certificate) throws -> CertificateIdentity {
        if let identity = certificate.identity {
            return identity
        }
        throw CertificateError("Certificate identity extraction requires a certificate inspector that can parse X.509 SANs")
    }

    public func fingerprint(of certificate: Certificate) throws -> Fingerprint {
        Fingerprint.sha256(der: certificate.der)
    }
}
