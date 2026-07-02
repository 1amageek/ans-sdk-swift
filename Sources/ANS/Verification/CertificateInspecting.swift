import Foundation

public protocol CertificateInspecting: Sendable {
    func identity(from certificate: Certificate) throws -> CertificateIdentity
    func fingerprint(of certificate: Certificate) throws -> Fingerprint
}
