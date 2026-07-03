import Testing
import ANS

@Suite("DNS")
struct DNSTests {
    @Test(.timeLimit(.minutes(1)))
    func parsesAnsBadgeRecord() throws {
        let record = try BadgeRecord(
            txt: "v=ans-badge1; version=v1.2.3; url=https://transparency.ans.godaddy.com/v1/agents/agent-1",
            source: .ansBadge
        )

        #expect(record.formatVersion == .ansBadge1)
        #expect(record.version == (try Version("1.2.3")))
        #expect(record.url.host == (try Host(rawValue: "transparency.ans.godaddy.com")))
        #expect(record.source == .ansBadge)
    }

    @Test(.timeLimit(.minutes(1)))
    func derivesDiscoveryNames() throws {
        let host = try Host(rawValue: "agent.example.com.")

        #expect(host.rawValue == "agent.example.com")
        #expect(host.ansBadgeName == "_ans-badge.agent.example.com")
        #expect(host.raBadgeName == "_ra-badge.agent.example.com")
        #expect(host.tlsaName(port: 443) == "_443._tcp.agent.example.com")
    }

    @Test(.timeLimit(.minutes(1)))
    func choosesPreferredRecordByNewestVersion() async throws {
        let host = try Host(rawValue: "agent.example.com")
        let old = BadgeRecord(
            formatVersion: .ansBadge1,
            version: try Version("1.0.0"),
            url: try URI(rawValue: "https://tl.example.com/v1/agents/old")
        )
        let new = BadgeRecord(
            formatVersion: .ansBadge1,
            version: try Version("2.0.0"),
            url: try URI(rawValue: "https://tl.example.com/v1/agents/new")
        )
        let discovery = BadgeDiscovery(resolver: StaticDNSResolver(records: [old, new]))

        let preferred = try await discovery.preferredRecord(for: host)

        #expect(preferred?.version == (try Version("2.0.0")))
    }
}

private struct StaticDNSResolver: DNSResolving {
    let records: [BadgeRecord]

    func lookupBadgeRecords(for host: Host) async throws(any Error) -> DNSLookupResult<BadgeRecord> {
        .found(records)
    }

    func lookupTLSARecords(for host: Host, port: UInt16) async throws(any Error) -> DNSLookupResult<TLSARecord> {
        .notFound
    }
}
