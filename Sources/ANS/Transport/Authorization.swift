public enum Authorization: Sendable, Hashable {
    case bearer(String)
    case jwt(String)
    case apiKey(id: String, secret: String)

    public var headerValue: String {
        switch self {
        case .bearer(let token):
            return "Bearer \(token)"
        case .jwt(let token):
            return "sso-jwt \(token)"
        case .apiKey(let id, let secret):
            return "sso-key \(id):\(secret)"
        }
    }
}
