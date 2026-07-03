public enum CertificateError: Error, Sendable, Equatable {
    case invalidDER(String)
    case invalidFingerprint
}
