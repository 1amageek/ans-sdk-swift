public protocol BadgeProviding: Sendable {
    func badge(for host: Host) throws -> Badge?
}
