public enum DNSLookupResult<Value: Sendable>: Sendable {
    case found([Value])
    case notFound
}
