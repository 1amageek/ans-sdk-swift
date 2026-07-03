#if !hasFeature(Embedded)
public protocol DNSResolving: Sendable {
    func lookupBadgeRecords(for host: Host) async throws(any Error) -> DNSLookupResult<BadgeRecord>
    func lookupTLSARecords(for host: Host, port: UInt16) async throws(any Error) -> DNSLookupResult<TLSARecord>
}
#endif
