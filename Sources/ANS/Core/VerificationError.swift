import Foundation

public struct VerificationError: Error, Sendable, Hashable, CustomStringConvertible {
    public enum Reason: Sendable, Hashable {
        case emptyCertificateChain
        case missingBadge
        case hostMismatch(expected: String, actual: String?)
        case rejectedStatus(String)
        case fingerprintMismatch
        case missingIdentityName
        case daneRequired
        case scittRequired
        case invalidEvidence(String)
    }

    public let reason: Reason

    public init(_ reason: Reason) {
        self.reason = reason
    }

    public var description: String {
        switch reason {
        case .emptyCertificateChain:
            return "Certificate chain is empty"
        case .missingBadge:
            return "ANS badge was not found"
        case let .hostMismatch(expected, actual):
            return "Badge host mismatch: expected \(expected), actual \(actual ?? "nil")"
        case let .rejectedStatus(status):
            return "Badge status is rejected: \(status)"
        case .fingerprintMismatch:
            return "Certificate fingerprint does not match ANS evidence"
        case .missingIdentityName:
            return "Identity certificate does not contain an ANS name"
        case .daneRequired:
            return "DANE evidence is required but unavailable or invalid"
        case .scittRequired:
            return "SCITT evidence is required but unavailable or invalid"
        case let .invalidEvidence(message):
            return message
        }
    }
}
