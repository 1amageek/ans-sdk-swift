public struct Endpoint: Sendable, Hashable {
    public let url: String
    public let protocolKind: String

    public init(url: String, protocolKind: String) {
        self.url = url
        self.protocolKind = protocolKind
    }
}
