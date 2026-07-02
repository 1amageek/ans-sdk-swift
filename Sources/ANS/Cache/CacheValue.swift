import Foundation

public enum CacheValue: Sendable, Hashable {
    case badge(Badge)
    case rootKeys([RootKey])
    case checkpoint(Checkpoint)
    case outcome(Outcome)
    case data(Data)
}
