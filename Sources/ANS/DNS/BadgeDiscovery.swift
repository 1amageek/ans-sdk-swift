#if !hasFeature(Embedded)
public struct BadgeDiscovery: Sendable {
    private let resolver: any DNSResolving

    public init(resolver: any DNSResolving) {
        self.resolver = resolver
    }

    public func records(for host: Host) async throws(any Error) -> [BadgeRecord] {
        switch try await resolver.lookupBadgeRecords(for: host) {
        case .found(let records):
            return records
        case .notFound:
            return []
        }
    }

    public func record(for host: Host, version: Version) async throws(any Error) -> BadgeRecord? {
        let records = try await records(for: host)
        if let exact = records.first(where: { $0.version == version }) {
            return exact
        }
        return records.first(where: { $0.version == nil })
    }

    public func preferredRecord(for host: Host) async throws(any Error) -> BadgeRecord? {
        let records = try await records(for: host)
        return records.sorted { lhs, rhs in
            switch (lhs.version, rhs.version) {
            case (.some(let lhsVersion), .some(let rhsVersion)):
                return lhsVersion > rhsVersion
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return false
            }
        }.first
    }
}
#endif
