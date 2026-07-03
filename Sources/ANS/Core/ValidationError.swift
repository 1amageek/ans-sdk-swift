public enum ValidationError: Error, Sendable, Equatable {
    case emptyEndpoints
    case endpointHostMismatch(expected: Host, actual: Host)
    case invalidDisplayName
    case invalidDescription
    case missingIdentityCSRPEM
    case missingTransparencyLogBaseURI
}
