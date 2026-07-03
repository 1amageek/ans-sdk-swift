public struct Configuration: Sendable, Hashable {
    public let registryBaseURI: URI
    public let transparencyLogBaseURI: URI?
    public let authorization: Authorization?

    public init(registryBaseURI: URI, transparencyLogBaseURI: URI? = nil, authorization: Authorization? = nil) {
        self.registryBaseURI = registryBaseURI
        self.transparencyLogBaseURI = transparencyLogBaseURI
        self.authorization = authorization
    }
}
