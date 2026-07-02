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

public struct Evidence: Sendable, Hashable {
    public let host: Host
    public let badge: Badge?
    public let fingerprint: Fingerprint?
    public let daneVerified: Bool
    public let scittVerified: Bool

    public init(host: Host, badge: Badge? = nil, fingerprint: Fingerprint? = nil, daneVerified: Bool = false, scittVerified: Bool = false) {
        self.host = host
        self.badge = badge
        self.fingerprint = fingerprint
        self.daneVerified = daneVerified
        self.scittVerified = scittVerified
    }
}
