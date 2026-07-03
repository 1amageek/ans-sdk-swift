public enum DANEPolicy: Sendable, Hashable {
    case disabled
    case validateIfPresent
    case required

    public var shouldVerify: Bool {
        self != .disabled
    }

    public var isRequired: Bool {
        self == .required
    }
}

#if !hasFeature(Embedded)
extension DANEPolicy: Codable {}
#endif
