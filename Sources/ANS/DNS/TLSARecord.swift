import Crypto

public struct TLSARecord: Sendable, Hashable {
    public enum Usage: UInt8, Sendable, Hashable {
        case caConstraint = 0
        case serviceCertificateConstraint = 1
        case trustAnchorAssertion = 2
        case domainIssuedCertificate = 3
    }

    public enum Selector: UInt8, Sendable, Hashable {
        case fullCertificate = 0
        case subjectPublicKeyInfo = 1
    }

    public enum MatchingType: UInt8, Sendable, Hashable {
        case noHash = 0
        case sha256 = 1
        case sha512 = 2
    }

    public let usage: Usage
    public let selector: Selector
    public let matchingType: MatchingType
    public let certificateAssociationData: [UInt8]
    public let dnssecSecure: Bool

    public init(
        usage: Usage,
        selector: Selector,
        matchingType: MatchingType,
        certificateAssociationData: [UInt8],
        dnssecSecure: Bool = false
    ) {
        self.usage = usage
        self.selector = selector
        self.matchingType = matchingType
        self.certificateAssociationData = certificateAssociationData
        self.dnssecSecure = dnssecSecure
    }

    public init(rdata: [UInt8], dnssecSecure: Bool = false) throws(ParsingError) {
        guard rdata.count >= 4 else {
            throw .invalidTLSARecord("TLSA record is too short")
        }
        guard let usage = Usage(rawValue: rdata[0]) else {
            throw .invalidTLSARecord("Invalid TLSA usage")
        }
        guard let selector = Selector(rawValue: rdata[1]) else {
            throw .invalidTLSARecord("Invalid TLSA selector")
        }
        guard let matchingType = MatchingType(rawValue: rdata[2]) else {
            throw .invalidTLSARecord("Invalid TLSA matching type")
        }

        self.usage = usage
        self.selector = selector
        self.matchingType = matchingType
        self.certificateAssociationData = Array(rdata.dropFirst(3))
        self.dnssecSecure = dnssecSecure
    }

    public func matches(certificate: CertificateIdentity) -> Bool? {
        guard usage == .domainIssuedCertificate else {
            return nil
        }

        let selectedBytes: [UInt8]
        switch selector {
        case .fullCertificate:
            guard let derBytes = certificate.derBytes else {
                return nil
            }
            selectedBytes = derBytes
        case .subjectPublicKeyInfo:
            guard let spkiBytes = certificate.subjectPublicKeyInfoBytes else {
                return nil
            }
            selectedBytes = spkiBytes
        }

        switch matchingType {
        case .noHash:
            return selectedBytes == certificateAssociationData
        case .sha256:
            return Array(SHA256.hash(data: selectedBytes)) == certificateAssociationData
        case .sha512:
            return Array(SHA512.hash(data: selectedBytes)) == certificateAssociationData
        }
    }
}

#if !hasFeature(Embedded)
extension TLSARecord.Usage: Codable {}
extension TLSARecord.Selector: Codable {}
extension TLSARecord.MatchingType: Codable {}
extension TLSARecord: Codable {}
#endif
