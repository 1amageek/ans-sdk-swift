public struct Response: Sendable, Hashable {
    public let statusCode: Int
    public let headers: [String: String]
    public let body: [UInt8]
    public let peerCertificateDER: [UInt8]?

    public init(
        statusCode: Int,
        headers: [String: String] = [:],
        body: [UInt8] = [],
        peerCertificateDER: [UInt8]? = nil
    ) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
        self.peerCertificateDER = peerCertificateDER
    }
}
