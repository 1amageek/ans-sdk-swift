import Foundation

public struct Page: Sendable, Hashable, Codable {
    public let limit: Int?
    public let cursor: String?

    public init(limit: Int? = nil, cursor: String? = nil) {
        self.limit = limit
        self.cursor = cursor
    }
}
