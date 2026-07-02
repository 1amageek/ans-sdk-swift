import Foundation

public struct ServiceBinding: Sendable, Hashable, Codable {
    public let priority: Int
    public let target: String
    public let parameters: [String: String]

    public init(priority: Int, target: String, parameters: [String: String] = [:]) {
        self.priority = priority
        self.target = target
        self.parameters = parameters
    }
}
