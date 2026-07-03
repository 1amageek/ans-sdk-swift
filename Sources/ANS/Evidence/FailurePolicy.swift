public enum FailurePolicy: Sendable, Hashable {
    case failClosed
    case failOpenWithCache(maximumStaleness: Duration = .seconds(600))
    case failOpen
}
