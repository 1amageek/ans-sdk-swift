import Crypto

public struct TrustedSCITTKey: Sendable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let keyID: [UInt8]
    public let spkiDER: [UInt8]
    let publicKey: P256.Signing.PublicKey

    public init(rootKey: RootKey) throws(SCITTError) {
        try self.init(name: rootKey.name, keyID: rootKey.keyID, spkiDER: rootKey.spkiDER)
    }

    public init(name: String, keyID: [UInt8], spkiDER: [UInt8]) throws(SCITTError) {
        guard keyID.count == 4 else {
            throw SCITTError.invalidToken("SCITT key id must be 4 bytes")
        }
        let computed = Array(SHA256.hash(data: spkiDER).prefix(4))
        guard computed == keyID else {
            throw SCITTError.invalidToken("SCITT key id does not match SHA-256(SPKI) prefix")
        }

        self.id = Hex.encode(keyID)
        self.name = name
        self.keyID = keyID
        self.spkiDER = spkiDER
        do {
            self.publicKey = try P256.Signing.PublicKey(derRepresentation: spkiDER)
        } catch {
            throw SCITTError.invalidToken("Invalid P-256 SPKI public key")
        }
    }

    public static func == (lhs: TrustedSCITTKey, rhs: TrustedSCITTKey) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.keyID == rhs.keyID && lhs.spkiDER == rhs.spkiDER
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(keyID)
        hasher.combine(spkiDER)
    }
}

public protocol SCITTKeyLookup: Sendable {
    func key(for keyID: [UInt8]) throws(SCITTError) -> TrustedSCITTKey
}

public struct SCITTKeyMergeResult: Sendable, Hashable {
    public let added: Int
    public let skippedUnparseable: Int
    public let skippedDuplicate: Int
    public let collisions: [String]

    public var skipped: Int {
        skippedUnparseable + skippedDuplicate
    }

    public init(added: Int, skippedUnparseable: Int, skippedDuplicate: Int, collisions: [String]) {
        self.added = added
        self.skippedUnparseable = skippedUnparseable
        self.skippedDuplicate = skippedDuplicate
        self.collisions = collisions
    }
}

public struct SCITTKeyStore: SCITTKeyLookup, Sendable, Hashable {
    private let keys: [String: TrustedSCITTKey]

    public init(rootKeys: [RootKey]) throws(SCITTError) {
        var parsed: [String: TrustedSCITTKey] = [:]
        for rootKey in rootKeys {
            let key = try TrustedSCITTKey(rootKey: rootKey)
            guard parsed[key.id] == nil else {
                throw SCITTError.invalidToken("Duplicate SCITT key id")
            }
            parsed[key.id] = key
        }
        self.keys = parsed
    }

    public init(c2spLines: [String]) throws(SCITTError) {
        var rootKeys: [RootKey] = []
        for line in c2spLines {
            let trimmed = line.trimmingANSWhitespaceForKeyStore()
            guard !trimmed.isEmpty else {
                continue
            }
            rootKeys.append(try RootKey(c2sp: trimmed))
        }
        try self.init(rootKeys: rootKeys)
    }

    public func key(for keyID: [UInt8]) throws(SCITTError) -> TrustedSCITTKey {
        let id = Hex.encode(keyID)
        guard let key = keys[id] else {
            throw SCITTError.unknownKeyID(keyID)
        }
        return key
    }

    public var count: Int {
        keys.count
    }

    public var isEmpty: Bool {
        keys.isEmpty
    }

    public func merging(c2spLines: [String]) -> (SCITTKeyStore, SCITTKeyMergeResult) {
        var merged = keys
        var added = 0
        var skippedUnparseable = 0
        var skippedDuplicate = 0
        var collisions: [String] = []

        for line in c2spLines {
            let trimmed = line.trimmingANSWhitespaceForKeyStore()
            guard !trimmed.isEmpty else {
                continue
            }

            let rootKey: RootKey
            do {
                rootKey = try RootKey(c2sp: trimmed)
            } catch {
                skippedUnparseable += 1
                continue
            }

            let key: TrustedSCITTKey
            do {
                key = try TrustedSCITTKey(rootKey: rootKey)
            } catch {
                skippedUnparseable += 1
                continue
            }

            if let existing = merged[key.id] {
                if existing.name != key.name {
                    collisions.append(key.id)
                }
                skippedDuplicate += 1
                continue
            }

            merged[key.id] = key
            added += 1
        }

        return (
            SCITTKeyStore(keys: merged),
            SCITTKeyMergeResult(
                added: added,
                skippedUnparseable: skippedUnparseable,
                skippedDuplicate: skippedDuplicate,
                collisions: collisions
            )
        )
    }

    public func merging(rootKeys: [RootKey]) -> (SCITTKeyStore, SCITTKeyMergeResult) {
        var merged = keys
        var added = 0
        var skippedUnparseable = 0
        var skippedDuplicate = 0
        var collisions: [String] = []

        for rootKey in rootKeys {
            let key: TrustedSCITTKey
            do {
                key = try TrustedSCITTKey(rootKey: rootKey)
            } catch {
                skippedUnparseable += 1
                continue
            }

            if let existing = merged[key.id] {
                if existing.name != key.name {
                    collisions.append(key.id)
                }
                skippedDuplicate += 1
                continue
            }

            merged[key.id] = key
            added += 1
        }

        return (
            SCITTKeyStore(keys: merged),
            SCITTKeyMergeResult(
                added: added,
                skippedUnparseable: skippedUnparseable,
                skippedDuplicate: skippedDuplicate,
                collisions: collisions
            )
        )
    }

    private init(keys: [String: TrustedSCITTKey]) {
        self.keys = keys
    }
}

private extension String {
    func trimmingANSWhitespaceForKeyStore() -> String {
        let bytes = Array(utf8)
        var start = 0
        var end = bytes.count
        while start < end, bytes[start].isANSKeyStoreWhitespace {
            start += 1
        }
        while end > start, bytes[end - 1].isANSKeyStoreWhitespace {
            end -= 1
        }
        return String(decoding: bytes[start..<end], as: UTF8.self)
    }
}

private extension UInt8 {
    var isANSKeyStoreWhitespace: Bool {
        self == 9 || self == 10 || self == 13 || self == 32
    }
}
