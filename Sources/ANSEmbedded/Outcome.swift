public enum Outcome: Sendable, Hashable {
    case verified
    case notANSAgent(Host)
    case rejected(VerificationError)

    public var isVerified: Bool {
        if case .verified = self { return true }
        return false
    }
}
