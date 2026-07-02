import Foundation

public enum Credential: Sendable, Hashable {
    case jwt(String)
    case apiKey(key: String, secret: String)
    case bearer(String)
    case none

    var authorizationHeader: String? {
        switch self {
        case let .jwt(token):
            return "sso-jwt \(token)"
        case let .apiKey(key, secret):
            return "sso-key \(key):\(secret)"
        case let .bearer(token):
            return "Bearer \(token)"
        case .none:
            return nil
        }
    }
}

extension Credential: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .jwt:
            return "Credential.jwt(<redacted>)"
        case .apiKey:
            return "Credential.apiKey(<redacted>)"
        case .bearer:
            return "Credential.bearer(<redacted>)"
        case .none:
            return "Credential.none"
        }
    }
}
