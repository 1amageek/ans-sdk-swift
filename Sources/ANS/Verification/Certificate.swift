import Foundation

public struct Certificate: Sendable, Hashable, Codable {
    public let der: Data
    public let identity: CertificateIdentity?

    public init(der: Data, identity: CertificateIdentity? = nil) {
        self.der = der
        self.identity = identity
    }
}
