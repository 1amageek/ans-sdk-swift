public struct RootKey: Sendable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let keyID: [UInt8]
    public let spkiDER: [UInt8]
    public let algorithm: WireValue

    public init(id: String, spkiDER: [UInt8], algorithm: WireValue = WireValue("ES256")) {
        self.id = id
        self.name = id
        do {
            self.keyID = try Hex.decode(id)
        } catch {
            self.keyID = []
        }
        self.spkiDER = spkiDER
        self.algorithm = algorithm
    }

    public init(name: String, keyID: [UInt8], spkiDER: [UInt8], algorithm: WireValue = WireValue("ES256")) {
        self.id = Hex.encode(keyID)
        self.name = name
        self.keyID = keyID
        self.spkiDER = spkiDER
        self.algorithm = algorithm
    }

    public init(c2sp: String) throws(SCITTError) {
        let parts = c2sp.split(separator: "+", omittingEmptySubsequences: false)
        guard parts.count == 3, !parts[0].isEmpty else {
            throw SCITTError.invalidToken("Invalid C2SP root key format")
        }
        let keyID: [UInt8]
        do {
            keyID = try Hex.decode(String(parts[1]))
        } catch {
            throw SCITTError.invalidToken("Invalid C2SP key id")
        }
        guard keyID.count == 4 else {
            throw SCITTError.invalidToken("Invalid C2SP key id length")
        }

        var spkiDER: [UInt8]
        do {
            spkiDER = try Base64.decode(String(parts[2]))
        } catch {
            throw SCITTError.invalidToken("Invalid C2SP public key")
        }
        if spkiDER.first == 0x02 {
            spkiDER.removeFirst()
        }

        self.init(name: String(parts[0]), keyID: keyID, spkiDER: spkiDER)
    }
}

#if !hasFeature(Embedded)
extension RootKey: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case keyID
        case spkiDER
        case algorithm
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let name = try container.decodeIfPresent(String.self, forKey: .name) ?? id
        let keyID: [UInt8]
        do {
            keyID = try container.decodeIfPresent([UInt8].self, forKey: .keyID) ?? Hex.decode(id)
        } catch {
            throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "\(error)")
        }
        let spkiDER = try container.decode([UInt8].self, forKey: .spkiDER)
        let algorithm = try container.decodeIfPresent(WireValue.self, forKey: .algorithm) ?? WireValue("ES256")
        self.init(name: name, keyID: keyID, spkiDER: spkiDER, algorithm: algorithm)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(keyID, forKey: .keyID)
        try container.encode(spkiDER, forKey: .spkiDER)
        try container.encode(algorithm, forKey: .algorithm)
    }
}
#endif
