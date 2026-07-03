public struct Page: Sendable, Hashable {
    public let limit: Int?
    public let offset: Int?
    public let cursor: String?

    public init(limit: Int? = nil, offset: Int? = nil, cursor: String? = nil) {
        self.limit = limit
        self.offset = offset
        self.cursor = cursor
    }
}

#if !hasFeature(Embedded)
extension Page: Codable {}
#endif
