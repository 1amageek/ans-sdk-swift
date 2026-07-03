public enum CryptoError: Error, Sendable, Equatable {
    case invalidObjectIdentifier(String)
    case invalidCommonName
    case signatureFailed
    case unsupportedKeyAlgorithm
}
