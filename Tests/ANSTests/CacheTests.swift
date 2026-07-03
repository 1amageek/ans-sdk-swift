import Testing
import ANS

@Suite("Cache")
struct CacheTests {
    @Test(.timeLimit(.minutes(1)))
    func storesAndReadsByHost() throws {
        let host = try Host(rawValue: "agent.example.com")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let badge = Badge(host: host, status: .active, serverFingerprint: fingerprint)
        let cache = Cache()

        cache.insert(badge, for: host)

        #expect(cache.entry(for: host)?.badge == badge)
        #expect(cache.count == 1)
    }

    @Test(.timeLimit(.minutes(1)))
    func tracksVersionedEntries() throws {
        let host = try Host(rawValue: "agent.example.com")
        let version = try Version("1.0.0")
        let name = Name(version: version, host: host)
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let badge = Badge(name: name, host: host, status: .active, serverFingerprint: fingerprint)
        let cache = Cache()

        cache.insert(badge, for: host)

        #expect(cache.entry(for: host, version: version)?.badge == badge)
        #expect(cache.entries(for: host).count == 2)
    }

    @Test(.timeLimit(.minutes(1)))
    func expiredEntryCanBeReadAsStaleWithinLimit() throws {
        let host = try Host(rawValue: "agent.example.com")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let badge = Badge(host: host, status: .active, serverFingerprint: fingerprint)
        let configuration = try Cache.Configuration(defaultTTL: .zero)
        let cache = Cache(configuration: configuration)

        cache.insert(badge, for: host)

        #expect(cache.entry(for: host) == nil)
        #expect(cache.staleEntry(for: host, maximumStaleness: .seconds(10))?.badge == badge)
    }

    @Test(.timeLimit(.minutes(1)))
    func zeroCapacityDoesNotRetainEntries() throws {
        let host = try Host(rawValue: "agent.example.com")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let badge = Badge(host: host, status: .active, serverFingerprint: fingerprint)
        let configuration = try Cache.Configuration(maxEntries: 0)
        let cache = Cache(configuration: configuration)

        cache.insert(badge, for: host)

        #expect(cache.entry(for: host) == nil)
        #expect(cache.count == 0)
    }
}
