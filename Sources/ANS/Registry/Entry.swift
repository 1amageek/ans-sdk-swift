public struct Entry: Sendable, Hashable {
    public struct ID: Sendable, Hashable, RawRepresentable, CustomStringConvertible {
        public let rawValue: String

        public var description: String {
            rawValue
        }

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public let id: ID

    public init(id: ID) {
        self.id = id
    }
}

#if !hasFeature(Embedded)
extension Entry.ID: Codable {}
extension Entry: Codable {}
#endif
