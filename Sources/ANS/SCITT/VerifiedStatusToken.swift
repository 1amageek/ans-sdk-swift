public struct VerifiedStatusToken: Sendable, Hashable {
    public let payload: StatusTokenPayload
    public let keyID: [UInt8]

    public init(payload: StatusTokenPayload, keyID: [UInt8] = []) {
        self.payload = payload
        self.keyID = keyID
    }
}

#if !hasFeature(Embedded)
extension VerifiedStatusToken: Codable {}
#endif
