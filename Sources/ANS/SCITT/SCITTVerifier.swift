#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

#if !hasFeature(Embedded)
public struct SCITTVerifier: SCITTVerifying, Sendable {
    private let keyLookup: any SCITTKeyLookup
    private let refreshableKeyStore: SCITTRefreshableKeyStore?
    private let currentUnixTime: @Sendable () -> Int64
    private let clockSkewSeconds: Int64

    public init(
        keyLookup: any SCITTKeyLookup,
        clockSkew: Duration = .seconds(60),
        currentUnixTime: @escaping @Sendable () -> Int64 = SCITTVerifier.defaultUnixTime
    ) {
        self.keyLookup = keyLookup
        self.refreshableKeyStore = keyLookup as? SCITTRefreshableKeyStore
        self.currentUnixTime = currentUnixTime
        self.clockSkewSeconds = Self.seconds(from: clockSkew)
    }

    public init(
        rootKeys: [RootKey],
        clockSkew: Duration = .seconds(60),
        currentUnixTime: @escaping @Sendable () -> Int64 = SCITTVerifier.defaultUnixTime
    ) throws(any Error) {
        self.init(
            keyLookup: try SCITTKeyStore(rootKeys: rootKeys),
            clockSkew: clockSkew,
            currentUnixTime: currentUnixTime
        )
    }

    public init(
        refreshableKeyStore: SCITTRefreshableKeyStore,
        clockSkew: Duration = .seconds(60),
        currentUnixTime: @escaping @Sendable () -> Int64 = SCITTVerifier.defaultUnixTime
    ) {
        self.keyLookup = refreshableKeyStore
        self.refreshableKeyStore = refreshableKeyStore
        self.currentUnixTime = currentUnixTime
        self.clockSkewSeconds = Self.seconds(from: clockSkew)
    }

    public func verifyReceipt(_ bytes: [UInt8]) async throws(any Error) -> VerifiedReceipt {
        let cose = try COSESign1(bytes: bytes)
        guard cose.protectedHeader.vds == 1 else {
            throw SCITTError.invalidToken("SCITT receipt must use RFC9162 vds=1")
        }
        let key = try await key(for: cose.protectedHeader.keyID)
        try cose.verifySignature(with: key)
        let proof = try Self.extractProof(from: cose.unprotected, eventBytes: cose.payload)
        return VerifiedReceipt(
            treeSize: proof.treeSize,
            leafIndex: proof.leafIndex,
            rootHash: proof.rootHash,
            eventBytes: cose.payload,
            keyID: cose.protectedHeader.keyID
        )
    }

    public func verifyStatusToken(_ bytes: [UInt8]) async throws(any Error) -> VerifiedStatusToken {
        let cose = try COSESign1(bytes: bytes)
        let key = try await key(for: cose.protectedHeader.keyID)
        try cose.verifySignature(with: key)
        let payload = try Self.decodeStatusPayload(cose.payload)

        if let expiresAt = payload.expiresAt,
           currentUnixTime() > expiresAt + clockSkewSeconds {
            throw SCITTError.invalidToken("SCITT status token expired")
        }
        guard !payload.status.shouldReject else {
            throw SCITTError.invalidStatus(payload.status)
        }

        return VerifiedStatusToken(payload: payload, keyID: cose.protectedHeader.keyID)
    }

    private func key(for keyID: [UInt8]) async throws(any Error) -> TrustedSCITTKey {
        let first = lookupKey(for: keyID)
        switch first {
        case .success(let key):
            return key
        case .failure(let error):
            guard case .unknownKeyID = error, let refreshableKeyStore else {
                throw error
            }
            _ = try await refreshableKeyStore.refreshIfCooldownElapsed()
            return try keyLookup.key(for: keyID)
        }
    }

    private func lookupKey(for keyID: [UInt8]) -> Result<TrustedSCITTKey, SCITTError> {
        do {
            return .success(try keyLookup.key(for: keyID))
        } catch {
            return .failure(error)
        }
    }

    private static func extractProof(from unprotected: CBOR.Item, eventBytes: [UInt8]) throws(SCITTError) -> (
        treeSize: UInt64,
        leafIndex: UInt64,
        rootHash: [UInt8]
    ) {
        guard case .map(let map) = unprotected.value,
              let vdp = map[.int(396)],
              case .map(let proofMap) = vdp.value else {
            throw .invalidToken("SCITT receipt missing VDP proof")
        }
        guard let treeSize = proofMap[.int(-1)]?.value.uint64Value,
              let leafIndex = proofMap[.int(-2)]?.value.uint64Value else {
            throw .invalidToken("SCITT receipt VDP missing tree_size or leaf_index")
        }

        var path: [[UInt8]] = []
        if let pathItem = proofMap[.int(-3)] {
            guard case .array(let items) = pathItem.value else {
                throw .invalidToken("SCITT receipt inclusion path must be an array")
            }
            guard items.count <= 63 else {
                throw .invalidToken("SCITT receipt inclusion path is too long")
            }
            for item in items {
                guard let hash = item.value.bytesValue, hash.count == 32 else {
                    throw .invalidToken("SCITT receipt inclusion path entries must be 32 bytes")
                }
                path.append(hash)
            }
        }

        let rootHash = try walkInclusionPath(eventBytes: eventBytes, leafIndex: leafIndex, treeSize: treeSize, path: path)
        return (treeSize, leafIndex, rootHash)
    }

    private static func decodeStatusPayload(_ bytes: [UInt8]) throws(SCITTError) -> StatusTokenPayload {
        let item: CBOR.Item
        do {
            item = try CBOR.decode(bytes)
        } catch {
            throw .invalidToken("Invalid status token payload CBOR: \(error)")
        }
        guard case .map(let map) = item.value else {
            throw .invalidToken("Status token payload must be a map")
        }

        guard let statusText = text(in: map, intKey: 2, textKey: "status") else {
            throw .invalidToken("Status token missing status")
        }
        guard let nameText = text(in: map, intKey: 5, textKey: "ans_name") else {
            throw .invalidToken("Status token missing ans_name")
        }

        let name: Name
        do {
            name = try Name(rawValue: nameText)
        } catch {
            throw .invalidToken("Invalid ans_name in status token")
        }

        let agentID = text(in: map, intKey: 1, textKey: "agent_id").map(Agent.ID.init(rawValue:))
        let status = Badge.Status(rawValue: statusText)
        let issuedAt = int(in: map, intKey: 3, textKey: "iat")
        let expiresAt = int(in: map, intKey: 4, textKey: "exp")
        guard expiresAt != nil else {
            throw .invalidToken("Status token missing exp")
        }

        return StatusTokenPayload(
            agentID: agentID,
            name: name,
            status: status,
            issuedAt: issuedAt,
            expiresAt: expiresAt,
            validIdentityCertificates: try certificateEntries(in: map, intKey: 6, textKey: "valid_identity_certs"),
            validServerCertificates: try certificateEntries(in: map, intKey: 7, textKey: "valid_server_certs"),
            metadataHashes: metadataHashes(in: map, intKey: 8, textKey: "metadata_hashes")
        )
    }

    private static func certificateEntries(
        in map: [CBOR.Key: CBOR.Item],
        intKey: Int64,
        textKey: String
    ) throws(SCITTError) -> [SCITTCertificateEntry] {
        guard let item = map[.int(intKey)] ?? map[.text(textKey)] else {
            return []
        }
        guard case .array(let values) = item.value else {
            throw .invalidToken("Status token certificate field must be an array")
        }
        guard values.count <= 128 else {
            throw .invalidToken("Status token certificate array is too long")
        }

        var entries: [SCITTCertificateEntry] = []
        for value in values {
            guard case .map(let certMap) = value.value else {
                continue
            }
            guard let fingerprint = fingerprint(in: certMap, intKey: 1, textKey: "fingerprint") else {
                continue
            }
            let certType = text(in: certMap, intKey: 2, textKey: "cert_type")
            let kind = certType.flatMap(SCITTCertificateEntry.Kind.init(rawValue:)) ?? .unknown
            entries.append(SCITTCertificateEntry(fingerprint: fingerprint, kind: kind))
        }
        return entries
    }

    private static func fingerprint(in map: [CBOR.Key: CBOR.Item], intKey: Int64, textKey: String) -> Fingerprint? {
        if let bytes = (map[.int(intKey)] ?? map[.text(textKey)])?.value.bytesValue, bytes.count == 32 {
            do {
                return try Fingerprint(algorithm: .sha256, bytes: bytes)
            } catch {
                return nil
            }
        }
        guard let text = text(in: map, intKey: intKey, textKey: textKey) else {
            return nil
        }
        do {
            if text.lowercased().hasPrefix("sha256:") {
                return try Fingerprint(rawValue: text)
            }
            return try Fingerprint(rawValue: "SHA256:\(text)")
        } catch {
            return nil
        }
    }

    private static func metadataHashes(
        in map: [CBOR.Key: CBOR.Item],
        intKey: Int64,
        textKey: String
    ) -> [String: String] {
        guard let item = map[.int(intKey)] ?? map[.text(textKey)],
              case .map(let values) = item.value else {
            return [:]
        }
        var output: [String: String] = [:]
        for (key, value) in values {
            guard case .text(let name) = key, let hash = value.value.textValue else {
                continue
            }
            output[name] = hash
        }
        return output
    }

    private static func text(in map: [CBOR.Key: CBOR.Item], intKey: Int64, textKey: String) -> String? {
        (map[.int(intKey)] ?? map[.text(textKey)])?.value.textValue
    }

    private static func int(in map: [CBOR.Key: CBOR.Item], intKey: Int64, textKey: String) -> Int64? {
        (map[.int(intKey)] ?? map[.text(textKey)])?.value.intValue
    }

    private static func walkInclusionPath(
        eventBytes: [UInt8],
        leafIndex: UInt64,
        treeSize: UInt64,
        path: [[UInt8]]
    ) throws(SCITTError) -> [UInt8] {
        guard treeSize > 0, leafIndex < treeSize else {
            throw .invalidToken("Invalid SCITT Merkle proof bounds")
        }

        var fn = leafIndex
        var sn = treeSize - 1
        var root = MerkleProof.leafHash(eventBytes)

        for node in path {
            guard sn != 0 else {
                throw .invalidToken("SCITT Merkle proof has excess path elements")
            }
            if fn & 1 == 1 || fn == sn {
                root = MerkleProof.nodeHash(left: node, right: root)
                while fn & 1 == 0 && fn != 0 {
                    fn >>= 1
                    sn >>= 1
                }
            } else {
                root = MerkleProof.nodeHash(left: root, right: node)
            }
            fn >>= 1
            sn >>= 1
        }

        guard sn == 0 else {
            throw .invalidToken("SCITT Merkle proof has insufficient path elements")
        }
        return root
    }

    private static func seconds(from duration: Duration) -> Int64 {
        let components = duration.components
        let seconds = components.seconds
        if seconds < 0 {
            return 0
        }
        if seconds > 600 {
            return 600
        }
        return seconds
    }

    public static func defaultUnixTime() -> Int64 {
#if canImport(FoundationEssentials) || canImport(Foundation)
        Int64(Date().timeIntervalSince1970)
#else
        0
#endif
    }
}

private extension CBOR.Value {
    var uint64Value: UInt64? {
        if case .unsigned(let value) = self {
            return value
        }
        return nil
    }
}
#endif
