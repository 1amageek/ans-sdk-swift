#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif
import Crypto

public struct CertificateSigningRequest: Sendable, Hashable {
    public let der: [UInt8]

    public var pem: String {
        PEM.encode(type: "CERTIFICATE REQUEST", der: der)
    }

    public init(der: [UInt8]) {
        self.der = der
    }
}

public protocol CSRGenerating: Sendable {
    func serverCSR(host: Host, keyPair: KeyPair) throws(CryptoError) -> CertificateSigningRequest
    func identityCSR(name: Name, keyPair: KeyPair) throws(CryptoError) -> CertificateSigningRequest
}

public struct CSRGenerator: CSRGenerating, Sendable {
    private enum OID {
        static let commonName = "2.5.4.3"
        static let extensionRequest = "1.2.840.113549.1.9.14"
        static let subjectAlternativeName = "2.5.29.17"
        static let ecdsaWithSHA256 = "1.2.840.10045.4.3.2"
        static let ecdsaWithSHA384 = "1.2.840.10045.4.3.3"
        static let ecdsaWithSHA512 = "1.2.840.10045.4.3.4"
    }

    public init() {}

    public func serverCSR(host: Host, keyPair: KeyPair) throws(CryptoError) -> CertificateSigningRequest {
        try makeCSR(commonName: host.rawValue, subjectAlternativeNames: [.dns(host.rawValue)], keyPair: keyPair)
    }

    public func identityCSR(name: Name, keyPair: KeyPair) throws(CryptoError) -> CertificateSigningRequest {
        try makeCSR(
            commonName: name.host.rawValue,
            subjectAlternativeNames: [
                .dns(name.host.rawValue),
                .uri(name.rawValue),
            ],
            keyPair: keyPair
        )
    }

    private func makeCSR(
        commonName: String,
        subjectAlternativeNames: [SubjectAlternativeName],
        keyPair: KeyPair
    ) throws(CryptoError) -> CertificateSigningRequest {
        guard !commonName.isEmpty else {
            throw CryptoError.invalidCommonName
        }
        let info = try certificationRequestInfo(
            commonName: commonName,
            subjectAlternativeNames: subjectAlternativeNames,
            publicKeyDER: keyPair.publicKeyDER
        )
        let request = try DER.sequence(
            info
                + signatureAlgorithm(for: keyPair.algorithm)
                + DER.bitString(try keyPair.signature(for: info))
        )
        return CertificateSigningRequest(der: request)
    }

    private func certificationRequestInfo(
        commonName: String,
        subjectAlternativeNames: [SubjectAlternativeName],
        publicKeyDER: [UInt8]
    ) throws(CryptoError) -> [UInt8] {
        try DER.sequence(
            DER.integer(0)
                + subject(commonName: commonName)
                + publicKeyDER
                + attributes(subjectAlternativeNames: subjectAlternativeNames)
        )
    }

    private func subject(commonName: String) throws(CryptoError) -> [UInt8] {
        try DER.sequence(
            DER.set(
                DER.sequence(
                    DER.objectIdentifier(OID.commonName)
                        + DER.utf8String(commonName)
                )
            )
        )
    }

    private func attributes(subjectAlternativeNames: [SubjectAlternativeName]) throws(CryptoError) -> [UInt8] {
        guard !subjectAlternativeNames.isEmpty else {
            return DER.taggedConstructed(0, content: [])
        }

        let generalNames = DER.sequence(subjectAlternativeNames.flatMap { $0.der })
        let subjectAlternativeNameExtension = try DER.sequence(
            DER.objectIdentifier(OID.subjectAlternativeName)
                + DER.octetString(generalNames)
        )
        let extensions = DER.sequence(subjectAlternativeNameExtension)
        let extensionRequest = try DER.sequence(
            DER.objectIdentifier(OID.extensionRequest)
                + DER.set(extensions)
        )
        return DER.taggedConstructed(0, content: extensionRequest)
    }

    private func signatureAlgorithm(for algorithm: KeyPair.Algorithm) throws(CryptoError) -> [UInt8] {
        switch algorithm {
        case .p256:
            return try DER.sequence(DER.objectIdentifier(OID.ecdsaWithSHA256))
        case .p384:
            return try DER.sequence(DER.objectIdentifier(OID.ecdsaWithSHA384))
        case .p521:
            return try DER.sequence(DER.objectIdentifier(OID.ecdsaWithSHA512))
        }
    }
}

private enum SubjectAlternativeName {
    case dns(String)
    case uri(String)

    var der: [UInt8] {
        switch self {
        case .dns(let value):
            return DER.taggedPrimitive(2, content: Array(value.utf8))
        case .uri(let value):
            return DER.taggedPrimitive(6, content: Array(value.utf8))
        }
    }
}
