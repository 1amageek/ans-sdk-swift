import Foundation

public struct Configuration: Sendable, Hashable {
    public let registryBaseURL: URL
    public let transparencyBaseURL: URL
    public let credential: Credential
    public let paths: Paths
    public let additionalHeaders: [String: String]

    public init(
        registryBaseURL: URL,
        transparencyBaseURL: URL? = nil,
        credential: Credential = .none,
        paths: Paths = .v1,
        additionalHeaders: [String: String] = [:]
    ) {
        self.registryBaseURL = registryBaseURL
        self.transparencyBaseURL = transparencyBaseURL ?? registryBaseURL
        self.credential = credential
        self.paths = paths
        self.additionalHeaders = additionalHeaders
    }
}
