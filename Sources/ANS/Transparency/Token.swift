import Foundation

public struct Token: Sendable, Hashable, Codable {
    public let bytes: Data

    public init(bytes: Data) {
        self.bytes = bytes
    }
}
