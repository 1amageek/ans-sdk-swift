#if !hasFeature(Embedded)
public enum SCITTPolicy: Sendable, Hashable {
    case withBadgeFallback
    case requireSCITT
    case badgeWithSCITTEnhancement
}
#endif
