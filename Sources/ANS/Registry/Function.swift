import Foundation

public struct Function: Sendable, Hashable, Codable, Identifiable {
    public let id: String
    public let name: String
    public let tags: [String]

    public init(id: String, name: String, tags: [String] = []) {
        self.id = id
        self.name = name
        self.tags = tags
    }
}
