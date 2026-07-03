public struct CertificateIdentity: Sendable, Hashable {
    public let commonName: String?
    public let dnsNames: [String]
    public let uriNames: [String]
    public let fingerprint: Fingerprint
    public let derBytes: [UInt8]?
    public let subjectPublicKeyInfoBytes: [UInt8]?

    public init(
        commonName: String? = nil,
        dnsNames: [String] = [],
        uriNames: [String] = [],
        fingerprint: Fingerprint,
        derBytes: [UInt8]? = nil,
        subjectPublicKeyInfoBytes: [UInt8]? = nil
    ) {
        self.commonName = commonName
        self.dnsNames = dnsNames
        self.uriNames = uriNames
        self.fingerprint = fingerprint
        self.derBytes = derBytes
        self.subjectPublicKeyInfoBytes = subjectPublicKeyInfoBytes
    }

    public init(derBytes: [UInt8]) throws(CertificateError) {
        let fingerprint: Fingerprint
        do {
            fingerprint = try Fingerprint.sha256(bytes: derBytes)
        } catch {
            throw .invalidFingerprint
        }
        let parsed = try CertificateParser.parse(derBytes)
        self.init(
            commonName: parsed.commonName,
            dnsNames: parsed.dnsNames,
            uriNames: parsed.uriNames,
            fingerprint: fingerprint,
            derBytes: derBytes,
            subjectPublicKeyInfoBytes: parsed.subjectPublicKeyInfoBytes
        )
    }

    public static func fromFingerprint(_ fingerprint: Fingerprint, commonName: String) -> CertificateIdentity {
        CertificateIdentity(commonName: commonName, dnsNames: [commonName], fingerprint: fingerprint)
    }

    public func host() throws(ParsingError) -> Host {
        if let dnsName = dnsNames.first {
            return try Host(rawValue: dnsName)
        }
        if let commonName {
            return try Host(rawValue: commonName)
        }
        throw .missingField("certificate host")
    }

    public func ansName() throws(ParsingError) -> Name {
        for uriName in uriNames where uriName.hasPrefix("ans://") {
            return try Name(rawValue: uriName)
        }
        throw .missingField("ANS URI SAN")
    }
}

#if !hasFeature(Embedded)
extension CertificateIdentity: Codable {}
#endif

private enum CertificateParser {
    struct Parsed: Sendable, Hashable {
        var commonName: String?
        var dnsNames: [String]
        var uriNames: [String]
        var subjectPublicKeyInfoBytes: [UInt8]
    }

    static func parse(_ der: [UInt8]) throws(CertificateError) -> Parsed {
        var certificate = DERReader(der)
        let certificateSequence = try certificate.read(tag: 0x30, name: "certificate")
        var certificateBody = DERReader(certificateSequence.content)
        let tbsCertificate = try certificateBody.read(tag: 0x30, name: "tbsCertificate")
        var tbs = DERReader(tbsCertificate.content)

        if tbs.peekTag() == 0xA0 {
            _ = try tbs.readElement(name: "version")
        }

        _ = try tbs.readElement(name: "serialNumber")
        _ = try tbs.readElement(name: "signature")
        _ = try tbs.readElement(name: "issuer")
        _ = try tbs.readElement(name: "validity")
        let subject = try tbs.read(tag: 0x30, name: "subject")
        let commonName = parseCommonName(subject.content)
        let subjectPublicKeyInfo = try tbs.read(tag: 0x30, name: "subjectPublicKeyInfo")

        var dnsNames: [String] = []
        var uriNames: [String] = []
        while !tbs.isAtEnd {
            let element = try tbs.readElement(name: "optional tbs field")
            guard element.tag == 0xA3 else {
                continue
            }
            let names = parseSubjectAlternativeNames(element.content)
            dnsNames.append(contentsOf: names.dnsNames)
            uriNames.append(contentsOf: names.uriNames)
        }

        return Parsed(
            commonName: commonName,
            dnsNames: dnsNames,
            uriNames: uriNames,
            subjectPublicKeyInfoBytes: subjectPublicKeyInfo.fullBytes
        )
    }

    private static func parseCommonName(_ subjectBytes: [UInt8]) -> String? {
        do {
            var subject = DERReader(subjectBytes)
            while !subject.isAtEnd {
                let set = try subject.read(tag: 0x31, name: "relativeDistinguishedName")
                var setReader = DERReader(set.content)
                while !setReader.isAtEnd {
                    let attribute = try setReader.read(tag: 0x30, name: "attribute")
                    var attributeReader = DERReader(attribute.content)
                    let oid = try attributeReader.read(tag: 0x06, name: "attribute oid")
                    let value = try attributeReader.readElement(name: "attribute value")
                    if oid.content == [0x55, 0x04, 0x03] {
                        return string(from: value)
                    }
                }
            }
        } catch {
            return nil
        }
        return nil
    }

    private static func parseSubjectAlternativeNames(_ explicitBytes: [UInt8]) -> (dnsNames: [String], uriNames: [String]) {
        do {
            var explicit = DERReader(explicitBytes)
            let extensions = try explicit.read(tag: 0x30, name: "extensions")
            var extensionReader = DERReader(extensions.content)
            var dnsNames: [String] = []
            var uriNames: [String] = []

            while !extensionReader.isAtEnd {
                let ext = try extensionReader.read(tag: 0x30, name: "extension")
                var extReader = DERReader(ext.content)
                let oid = try extReader.read(tag: 0x06, name: "extension oid")
                if extReader.peekTag() == 0x01 {
                    _ = try extReader.readElement(name: "critical")
                }
                let value = try extReader.read(tag: 0x04, name: "extension value")
                guard oid.content == [0x55, 0x1D, 0x11] else {
                    continue
                }

                var san = DERReader(value.content)
                let names = try san.read(tag: 0x30, name: "subjectAltName")
                var namesReader = DERReader(names.content)
                while !namesReader.isAtEnd {
                    let name = try namesReader.readElement(name: "generalName")
                    if name.tag == 0x82 {
                        dnsNames.append(String(decoding: name.content, as: UTF8.self))
                    } else if name.tag == 0x86 {
                        uriNames.append(String(decoding: name.content, as: UTF8.self))
                    }
                }
            }
            return (dnsNames, uriNames)
        } catch {
            return ([], [])
        }
    }

    private static func string(from element: DERElement) -> String? {
        switch element.tag {
        case 0x0C, 0x13, 0x16, 0x14:
            return String(decoding: element.content, as: UTF8.self)
        case 0x1E:
            var scalars: [UInt16] = []
            var index = 0
            while index + 1 < element.content.count {
                scalars.append(UInt16(element.content[index]) << 8 | UInt16(element.content[index + 1]))
                index += 2
            }
            return String(decoding: scalars, as: UTF16.self)
        default:
            return nil
        }
    }
}

private struct DERElement {
    let tag: UInt8
    let content: [UInt8]
    let fullBytes: [UInt8]
}

private struct DERReader {
    private let bytes: [UInt8]
    private var offset: Int

    var isAtEnd: Bool {
        offset >= bytes.count
    }

    init(_ bytes: [UInt8]) {
        self.bytes = bytes
        self.offset = 0
    }

    func peekTag() -> UInt8? {
        guard offset < bytes.count else {
            return nil
        }
        return bytes[offset]
    }

    mutating func read(tag expectedTag: UInt8, name: String) throws(CertificateError) -> DERElement {
        let element = try readElement(name: name)
        guard element.tag == expectedTag else {
            throw .invalidDER("Expected \(name) tag \(expectedTag), got \(element.tag)")
        }
        return element
    }

    mutating func readElement(name: String) throws(CertificateError) -> DERElement {
        let start = offset
        guard offset < bytes.count else {
            throw .invalidDER("Unexpected end while reading \(name)")
        }

        let tag = bytes[offset]
        offset += 1
        let length = try readLength(name: name)
        guard offset + length <= bytes.count else {
            throw .invalidDER("Length exceeds input while reading \(name)")
        }

        let contentStart = offset
        let contentEnd = offset + length
        offset = contentEnd
        return DERElement(
            tag: tag,
            content: Array(bytes[contentStart..<contentEnd]),
            fullBytes: Array(bytes[start..<contentEnd])
        )
    }

    private mutating func readLength(name: String) throws(CertificateError) -> Int {
        guard offset < bytes.count else {
            throw .invalidDER("Missing length for \(name)")
        }
        let first = bytes[offset]
        offset += 1
        if first & 0x80 == 0 {
            return Int(first)
        }

        let count = Int(first & 0x7F)
        guard count > 0, count <= 4, offset + count <= bytes.count else {
            throw .invalidDER("Invalid length for \(name)")
        }

        var length = 0
        for _ in 0..<count {
            length = (length << 8) | Int(bytes[offset])
            offset += 1
        }
        return length
    }
}
