public enum BadgeRecordSource: Sendable, Hashable {
    case ansBadge
    case raBadge
}

#if !hasFeature(Embedded)
extension BadgeRecordSource: Codable {}
#endif
