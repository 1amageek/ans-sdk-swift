import Foundation

public struct ParsingError: Error, Sendable, Equatable, CustomStringConvertible {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var description: String { message }
}

public struct ValidationError: Error, Sendable, Equatable, CustomStringConvertible {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var description: String { message }
}

public struct TransportError: Error, Sendable, Equatable, CustomStringConvertible {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var description: String { message }
}

public struct ServerError: Error, Sendable, Equatable, CustomStringConvertible {
    public let statusCode: Int
    public let body: Data

    public init(statusCode: Int, body: Data) {
        self.statusCode = statusCode
        self.body = body
    }

    public var description: String {
        "Server returned HTTP \(statusCode)"
    }
}

public struct ResolutionError: Error, Sendable, Equatable, CustomStringConvertible {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var description: String { message }
}

public struct CertificateError: Error, Sendable, Equatable, CustomStringConvertible {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var description: String { message }
}

public struct CryptoError: Error, Sendable, Equatable, CustomStringConvertible {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var description: String { message }
}

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
