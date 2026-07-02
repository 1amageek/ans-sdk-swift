import Foundation

public enum Policy: Sendable, Hashable, Codable {
    case pkiOnly
    case badgeRequired
    case daneAdvisory
    case daneRequired
    case daneAndBadge
    case scittEnhanced
    case scittRequired

    public static let `default`: Policy = .badgeRequired

    var requiresBadge: Bool {
        switch self {
        case .pkiOnly:
            return false
        case .badgeRequired, .daneAdvisory, .daneRequired, .daneAndBadge, .scittEnhanced, .scittRequired:
            return true
        }
    }

    var requiresDANE: Bool {
        self == .daneRequired || self == .daneAndBadge
    }

    var requiresSCITT: Bool {
        self == .scittRequired
    }
}
