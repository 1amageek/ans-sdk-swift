import Foundation

public enum Outcome: Sendable, Hashable {
    case verified(Evidence)
    case notANSAgent(Host)
    case degraded(Evidence, reason: String)
    case rejected(VerificationError)

    public var isVerified: Bool {
        if case .verified = self { return true }
        return false
    }
}
