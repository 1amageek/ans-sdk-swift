import Foundation

public struct Resolution: Sendable, Hashable, Codable {
    public let agent: Agent
    public let endpoint: Endpoint?

    public init(agent: Agent, endpoint: Endpoint? = nil) {
        self.agent = agent
        self.endpoint = endpoint
    }
}
