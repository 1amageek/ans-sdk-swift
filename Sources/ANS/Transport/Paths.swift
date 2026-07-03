public struct Paths: Sendable, Hashable {
    public enum Generation: Sendable, Hashable {
        case v1
    }

    public let generation: Generation

    public init(generation: Generation = .v1) {
        self.generation = generation
    }

    public func badgePath(for agentID: Agent.ID) -> String {
        switch generation {
        case .v1:
            return "/v1/agents/\(URI.percentEncode(agentID.rawValue))"
        }
    }

    public func auditPath(for agentID: Agent.ID) -> String {
        switch generation {
        case .v1:
            return "/v1/agents/\(URI.percentEncode(agentID.rawValue))/audit"
        }
    }

    public func receiptPath(for agentID: Agent.ID) -> String {
        "/v1/agents/\(URI.percentEncode(agentID.rawValue))/receipt"
    }

    public func statusTokenPath(for agentID: Agent.ID) -> String {
        "/v1/agents/\(URI.percentEncode(agentID.rawValue))/status-token"
    }

    public func identityBadgePath(for identityID: Identity.ID) -> String {
        "/v1/identities/\(URI.percentEncode(identityID.rawValue))"
    }

    public func identityAuditPath(for identityID: Identity.ID) -> String {
        "\(identityBadgePath(for: identityID))/audit"
    }

    public func identityReceiptPath(for identityID: Identity.ID) -> String {
        "\(identityBadgePath(for: identityID))/receipt"
    }

    public func identityAgentsPath(for identityID: Identity.ID) -> String {
        "\(identityBadgePath(for: identityID))/agents"
    }

    public func agentIdentitiesPath(for agentID: Agent.ID) -> String {
        "/v1/agents/\(URI.percentEncode(agentID.rawValue))/identities"
    }

    public func agentIdentityHistoryPath(for agentID: Agent.ID) -> String {
        "\(agentIdentitiesPath(for: agentID))/history"
    }

    public var checkpointPath: String {
        "/v1/log/checkpoint"
    }

    public var rawCheckpointPath: String {
        "/checkpoint"
    }

    public func tilePath(level: Int, index: Int) -> String {
        "/tile/\(level)/\(index)"
    }

    public func partialTilePath(level: Int, index: Int, width: Int) -> String {
        "/tile/\(level)/\(index).p/\(width)"
    }

    public func entryTilePath(index: Int) -> String {
        "/tile/entries/\(index)"
    }

    public func partialEntryTilePath(index: Int, width: Int) -> String {
        "/tile/entries/\(index).p/\(width)"
    }

    public var checkpointHistoryPath: String {
        "/v1/log/checkpoint/history"
    }

    public func schemaPath(version: String) -> String {
        "/v1/log/schema/\(URI.percentEncode(version))"
    }

    public var registerPath: String {
        "/v1/agents/register"
    }

    public func agentPath(id: Agent.ID) -> String {
        "/v1/agents/\(URI.percentEncode(id.rawValue))"
    }

    public func challengePath(agentID: Agent.ID) -> String {
        "\(agentPath(id: agentID))/challenge"
    }

    public func verifyACMEPath(agentID: Agent.ID) -> String {
        "\(agentPath(id: agentID))/verify-acme"
    }

    public func verifyDNSPath(agentID: Agent.ID) -> String {
        "\(agentPath(id: agentID))/verify-dns"
    }

    public var searchPath: String {
        "/v1/agents"
    }

    public var resolutionPath: String {
        "/v1/agents/resolution"
    }

    public func certificatesPath(agentID: Agent.ID, kind: Certificate.Kind) -> String {
        let component: String
        switch kind {
        case .server:
            component = "server"
        case .identity:
            component = "identity"
        }
        return "\(agentPath(id: agentID))/certificates/\(component)"
    }

    public func csrStatusPath(agentID: Agent.ID, csrID: String) -> String {
        "\(agentPath(id: agentID))/csrs/\(URI.percentEncode(csrID))/status"
    }

    public var eventsPath: String {
        "/v1/agents/events"
    }

    public func revokePath(agentID: Agent.ID) -> String {
        "\(agentPath(id: agentID))/revoke"
    }

    public var agentsPath: String {
        "/ans/agents"
    }

    public func v2AgentPath(id: Agent.ID) -> String {
        "\(agentsPath)/\(URI.percentEncode(id.rawValue))"
    }

    public func validateRegistrationPath(agentID: Agent.ID) -> String {
        "\(v2AgentPath(id: agentID))/verify-acme"
    }

    public func verifyDNSRecordsPath(agentID: Agent.ID) -> String {
        "\(v2AgentPath(id: agentID))/verify-dns"
    }

    public func v2RevokePath(agentID: Agent.ID) -> String {
        "\(v2AgentPath(id: agentID))/revoke"
    }

    public func agentCertificatesPath(agentID: Agent.ID, kind: Certificate.Kind) -> String {
        let component: String
        switch kind {
        case .server:
            component = "server"
        case .identity:
            component = "identity"
        }
        return "\(v2AgentPath(id: agentID))/certificates/\(component)"
    }

    public func agentCSRStatusPath(agentID: Agent.ID, csrID: String) -> String {
        "\(v2AgentPath(id: agentID))/csrs/\(URI.percentEncode(csrID))/status"
    }

    public func serverCertificateRenewalPath(agentID: Agent.ID) -> String {
        "/ans/agents/\(URI.percentEncode(agentID.rawValue))/certificates/server/renewal"
    }

    public func verifyRenewalACMEPath(agentID: Agent.ID) -> String {
        "\(serverCertificateRenewalPath(agentID: agentID))/verify-acme"
    }

    public var identitiesPath: String {
        "/ans/identities"
    }

    public func identityPath(id: Identity.ID) -> String {
        "/ans/identities/\(URI.percentEncode(id.rawValue))"
    }

    public func verifyIdentityControlPath(id: Identity.ID) -> String {
        "\(identityPath(id: id))/verify-control"
    }

    public func revokeIdentityPath(id: Identity.ID) -> String {
        "\(identityPath(id: id))/revoke"
    }

    public func identityLinksPath(id: Identity.ID) -> String {
        "\(identityPath(id: id))/links"
    }

    public func identityLinkPath(id: Identity.ID, agentID: Agent.ID) -> String {
        "\(identityLinksPath(id: id))/\(URI.percentEncode(agentID.rawValue))"
    }
}
