import Foundation

public struct Revocation: Sendable, Hashable, Codable {
    public struct Reason: CanonicalWireValue, ExpressibleByStringLiteral {
        public let rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: String) {
            self.init(value)
        }

        public static let keyCompromise = Self("KEY_COMPROMISE")
        public static let cessationOfOperation = Self("CESSATION_OF_OPERATION")
        public static let affiliationChanged = Self("AFFILIATION_CHANGED")
        public static let superseded = Self("SUPERSEDED")
        public static let certificateHold = Self("CERTIFICATE_HOLD")
        public static let privilegeWithdrawn = Self("PRIVILEGE_WITHDRAWN")
        public static let aaCompromise = Self("AA_COMPROMISE")
    }

    public let reason: Reason
    public let comments: String?

    public init(reason: Reason, comments: String? = nil) {
        self.reason = reason
        self.comments = comments
    }
}
