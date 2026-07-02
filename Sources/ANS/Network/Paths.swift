import Foundation

public struct Paths: Sendable, Hashable {
    public enum Generation: Sendable, Hashable {
        case v1
        case ans
    }

    public let generation: Generation

    public init(generation: Generation) {
        self.generation = generation
    }

    public static let v1 = Paths(generation: .v1)
    public static let ans = Paths(generation: .ans)

    public func registerAgent() -> String {
        switch generation {
        case .v1:
            return "/v1/agents/register"
        case .ans:
            return "/ans/agents"
        }
    }

    public func agent(_ id: Agent.ID) -> String {
        switch generation {
        case .v1:
            return "/v1/agents/\(id.rawValue)"
        case .ans:
            return "/ans/agents/\(id.rawValue)"
        }
    }

    public func searchAgents() -> String {
        switch generation {
        case .v1:
            return "/v1/agents"
        case .ans:
            return "/ans/agents"
        }
    }

    public func resolveAgent() -> String {
        switch generation {
        case .v1:
            return "/v1/agents/resolution"
        case .ans:
            return "/ans/agents/resolution"
        }
    }

    public func verifyACME(_ id: Agent.ID) -> String {
        "\(agent(id))/verify-acme"
    }

    public func verifyDNS(_ id: Agent.ID) -> String {
        "\(agent(id))/verify-dns"
    }

    public func revoke(_ id: Agent.ID) -> String {
        "\(agent(id))/revoke"
    }

    public func identityCertificates(_ id: Agent.ID) -> String {
        "\(agent(id))/certificates/identity"
    }

    public func serverCertificates(_ id: Agent.ID) -> String {
        "\(agent(id))/certificates/server"
    }

    public func events(_ id: Agent.ID) -> String {
        "\(agent(id))/events"
    }

    public func badge(_ id: Agent.ID) -> String {
        "/v1/agents/\(id.rawValue)"
    }

    public func audit(_ id: Agent.ID) -> String {
        "/v1/agents/\(id.rawValue)/audit"
    }

    public func receipt(_ id: Agent.ID) -> String {
        "/v1/agents/\(id.rawValue)/receipt"
    }

    public func statusToken(_ id: Agent.ID) -> String {
        "/v1/agents/\(id.rawValue)/status-token"
    }

    public func checkpoint() -> String {
        "/v1/log/checkpoint"
    }

    public func checkpointHistory() -> String {
        "/v1/log/checkpoint/history"
    }

    public func schema(_ version: String) -> String {
        "/v1/log/schema/\(version)"
    }

    public func rootKeys() -> String {
        "/root-keys"
    }
}

extension URL {
    func ansAppendingPath(_ path: String) -> URL {
        var url = self
        for component in path.split(separator: "/").map(String.init) {
            url.appendPathComponent(component)
        }
        return url
    }

    func ansAppendingQuery(_ items: [URLQueryItem]) -> URL {
        guard !items.isEmpty, var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }
        components.queryItems = (components.queryItems ?? []) + items
        return components.url ?? self
    }
}
