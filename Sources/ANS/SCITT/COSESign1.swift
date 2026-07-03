import Crypto

struct COSESign1: Sendable, Hashable {
    struct ProtectedHeader: Sendable, Hashable {
        let algorithm: Int64
        let keyID: [UInt8]
        let vds: Int64?
        let issuer: String?
        let issuedAt: Int64?
    }

    let protectedBytes: [UInt8]
    let protectedHeader: ProtectedHeader
    let unprotected: CBOR.Item
    let payload: [UInt8]
    let signature: [UInt8]

    init(bytes: [UInt8]) throws(SCITTError) {
        guard bytes.count <= 1 << 20 else {
            throw .invalidToken("COSE_Sign1 input exceeds 1 MiB")
        }

        let outer: CBOR.Item
        do {
            outer = try CBOR.decode(bytes)
        } catch {
            throw .invalidToken("Invalid COSE_Sign1 CBOR: \(error)")
        }

        let arrayItem: CBOR.Item
        switch outer.value {
        case .tag(let tag, let item) where tag == 18:
            arrayItem = item
        default:
            arrayItem = outer
        }

        guard case .array(let elements) = arrayItem.value, elements.count == 4 else {
            throw .invalidToken("COSE_Sign1 must be a four element array")
        }
        guard let protectedBytes = elements[0].value.bytesValue else {
            throw .invalidToken("COSE protected header must be a byte string")
        }
        guard let payload = elements[2].value.bytesValue, !payload.isEmpty else {
            throw .invalidToken("COSE payload must be a non-empty byte string")
        }
        guard let signature = elements[3].value.bytesValue, signature.count == 64 else {
            throw .invalidToken("COSE ES256 signature must be 64-byte P1363")
        }

        self.protectedBytes = protectedBytes
        self.protectedHeader = try Self.parseProtectedHeader(protectedBytes)
        self.unprotected = elements[1]
        self.payload = payload
        self.signature = signature
    }

    func verifySignature(with key: TrustedSCITTKey) throws(SCITTError) {
        if let issuer = protectedHeader.issuer, issuer != key.name {
            throw .invalidToken("COSE issuer does not match trusted key name")
        }

        let sigStructure = CBOR.encodeSigStructure(protectedBytes: protectedBytes, payload: payload)
        let digest = SHA256.hash(data: sigStructure)
        let signature: P256.Signing.ECDSASignature
        do {
            signature = try P256.Signing.ECDSASignature(rawRepresentation: self.signature)
        } catch {
            throw .invalidToken("Invalid ES256 signature encoding")
        }

        guard key.publicKey.isValidSignature(signature, for: digest) else {
            throw .invalidToken("COSE signature verification failed")
        }
    }

    private static func parseProtectedHeader(_ bytes: [UInt8]) throws(SCITTError) -> ProtectedHeader {
        let item: CBOR.Item
        do {
            item = try CBOR.decode(bytes)
        } catch {
            throw .invalidToken("Invalid COSE protected header CBOR: \(error)")
        }

        guard case .map(let map) = item.value else {
            throw .invalidToken("COSE protected header must be a map")
        }

        let algorithm = map[.int(1)]?.value.intValue
        guard algorithm == -7 else {
            throw .invalidToken("Unsupported COSE algorithm")
        }

        guard let keyID = map[.int(4)]?.value.bytesValue, keyID.count == 4 else {
            throw .invalidToken("COSE protected header missing 4-byte kid")
        }

        let cwtClaims = cwtClaims(from: map[.int(15)])
        return ProtectedHeader(
            algorithm: -7,
            keyID: keyID,
            vds: map[.int(395)]?.value.intValue,
            issuer: cwtClaims.issuer,
            issuedAt: cwtClaims.issuedAt
        )
    }

    private static func cwtClaims(from item: CBOR.Item?) -> (issuer: String?, issuedAt: Int64?) {
        guard let item, case .map(let map) = item.value else {
            return (nil, nil)
        }
        return (map[.int(1)]?.value.textValue, map[.int(6)]?.value.intValue)
    }
}
