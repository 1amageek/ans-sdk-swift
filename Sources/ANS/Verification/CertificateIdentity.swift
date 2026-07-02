import Foundation

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
