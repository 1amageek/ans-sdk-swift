public struct Resolution: Sendable, Hashable {
    public let agent: Agent
    public let endpoint: Endpoint?

    public init(agent: Agent, endpoint: Endpoint? = nil) {
        self.agent = agent
        self.endpoint = endpoint
    }
}

#if !hasFeature(Embedded)
extension Resolution: Codable {}
#endif
