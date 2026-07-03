public enum Policy: Sendable, Hashable {
    case pkiOnly
    case badgeRequired
    case allowDeprecatedBadge
}

#if !hasFeature(Embedded)
extension Policy: Codable {}
#endif
