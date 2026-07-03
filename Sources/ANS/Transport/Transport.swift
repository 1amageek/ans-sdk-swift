#if !hasFeature(Embedded)
public protocol Transport: Sendable {
    func send(_ request: Request) async throws(any Error) -> Response
}
#endif
