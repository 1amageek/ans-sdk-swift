#if !hasFeature(Embedded)
public protocol SCITTVerifying: Sendable {
    func verifyReceipt(_ bytes: [UInt8]) async throws(any Error) -> VerifiedReceipt
    func verifyStatusToken(_ bytes: [UInt8]) async throws(any Error) -> VerifiedStatusToken
}
#endif
