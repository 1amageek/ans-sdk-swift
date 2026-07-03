#if !hasFeature(Embedded)
public enum ReceiptPolicy: Sendable, Hashable {
    case optional
    case required
}

extension SCITTPolicy {
    var receiptPolicy: ReceiptPolicy {
        switch self {
        case .requireSCITT:
            .required
        case .withBadgeFallback, .badgeWithSCITTEnhancement:
            .optional
        }
    }
}
#endif
