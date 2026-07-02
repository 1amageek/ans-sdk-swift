import Foundation

public struct RootKey: Sendable, Hashable, Codable {
    public let origin: String
    public let keyID: Data
    public let spkiDER: Data
    public let rawLine: String

    public init(origin: String, keyID: Data, spkiDER: Data, rawLine: String) {
        self.origin = origin
        self.keyID = keyID
        self.spkiDER = spkiDER
        self.rawLine = rawLine
    }

    public init(line: String) throws {
        let parts = line.split(separator: "+", omittingEmptySubsequences: false)
        guard parts.count == 3 else {
            throw ParsingError("Root key line must have origin, key hash, and key material")
        }
        let keyID = try Data(ansHexString: String(parts[1]))
        guard let encoded = Data(base64Encoded: String(parts[2])), encoded.first == 0x02 else {
            throw ParsingError("Root key material must be base64(0x02 || SPKI-DER)")
        }
        self.origin = String(parts[0])
        self.keyID = keyID
        self.spkiDER = encoded.dropFirst()
        self.rawLine = line
    }
}
