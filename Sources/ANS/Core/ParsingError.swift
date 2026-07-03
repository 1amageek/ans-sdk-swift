public enum ParsingError: Error, Sendable, Equatable {
    case emptyValue
    case missingField(String)
    case invalidScheme(expected: String)
    case invalidVersion(String)
    case invalidHost(String)
    case invalidName(String)
    case invalidURI(String)
    case invalidFingerprint(String)
    case invalidBadgeRecord(String)
    case invalidTLSARecord(String)
    case unsupportedAlgorithm(String)
}
