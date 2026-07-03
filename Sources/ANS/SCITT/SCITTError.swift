public enum SCITTError: Error, Sendable, Equatable {
    case missingHeaders
    case partialHeaders
    case invalidStatus(Badge.Status)
    case fingerprintMismatch
    case hostMismatch(expected: Host, actual: Host)
    case unknownKeyID([UInt8])
    case invalidToken(String)
}
