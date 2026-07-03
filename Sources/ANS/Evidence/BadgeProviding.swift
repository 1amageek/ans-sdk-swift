#if !hasFeature(Embedded)
public protocol BadgeProviding: Sendable {
    func badge(for host: Host) async throws(any Error) -> Badge?
}

public protocol VersionedBadgeProviding: BadgeProviding {
    func badge(for host: Host, version: Version) async throws(any Error) -> Badge?
}
#endif
