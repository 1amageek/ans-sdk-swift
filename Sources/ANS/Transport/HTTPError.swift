#if !hasFeature(Embedded)
public struct HTTPError: Error, Sendable, Equatable {
    public let statusCode: Int
    public let body: [UInt8]

    public init(statusCode: Int, body: [UInt8]) {
        self.statusCode = statusCode
        self.body = body
    }
}
#endif
