#if !hasFeature(Embedded)
public protocol SCITTArtifactFetching: Sendable {
    func receipt(agentID: Agent.ID) async throws(any Error) -> [UInt8]
    func statusToken(agentID: Agent.ID) async throws(any Error) -> [UInt8]
    func rootKeys() async throws(any Error) -> [RootKey]
}

extension TransparencyLogClient: SCITTArtifactFetching {}
#endif
