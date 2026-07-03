import Synchronization
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

    @Test(.timeLimit(.minutes(1)))
    func rejectsNegativeConfigurationValues() {
        #expect(throws: Cache.ConfigurationError.self) {
            try Cache.Configuration(maxEntries: -1)
        }
        #expect(throws: Cache.ConfigurationError.self) {
            try Cache.Configuration(defaultTTL: .seconds(-1))
        }
        #expect(throws: Cache.ConfigurationError.self) {
            try Cache.Configuration(refreshThreshold: .seconds(-1))
        }
        #expect(throws: Cache.ConfigurationError.self) {
            try Cache.Configuration(staleRetention: .seconds(-1))
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func invalidatesHostEntriesAndVersionIndex() throws {
        let host = try Host(rawValue: "agent.example.com")
        let version = try Version("1.0.0")
        let name = Name(version: version, host: host)
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let badge = Badge(name: name, host: host, status: .active, serverFingerprint: fingerprint)
        let cache = Cache()

        cache.insert(badge, for: host)
        cache.invalidate(host: host)

        #expect(cache.entry(for: host) == nil)
        #expect(cache.entry(for: host, version: version) == nil)
        #expect(cache.entries(for: host).isEmpty)
        #expect(cache.count == 0)
    }

    @Test(.timeLimit(.minutes(1)))
    func invalidatesSingleVersionWithoutDroppingHostEntry() throws {
        let host = try Host(rawValue: "agent.example.com")
        let version = try Version("1.0.0")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let hostBadge = Badge(host: host, status: .active, serverFingerprint: fingerprint)
        let versionedBadge = Badge(name: Name(version: version, host: host), host: host, status: .active, serverFingerprint: fingerprint)
        let cache = Cache()

        cache.insert(hostBadge, for: host)
        cache.insert(versionedBadge, for: host, version: version)
        cache.invalidate(host: host, version: version)

        #expect(cache.entry(for: host)?.badge == hostBadge)
        #expect(cache.entry(for: host, version: version) == nil)
        #expect(cache.entries(for: host).count == 1)
    }

    @Test(.timeLimit(.minutes(1)))
    func removeAllClearsEntriesAndVersionIndex() throws {
        let host = try Host(rawValue: "agent.example.com")
        let version = try Version("1.0.0")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let badge = Badge(name: Name(version: version, host: host), host: host, status: .active, serverFingerprint: fingerprint)
        let cache = Cache()

        cache.insert(badge, for: host)
        cache.removeAll()

        #expect(cache.entry(for: host) == nil)
        #expect(cache.entries(for: host).isEmpty)
        #expect(cache.count == 0)
    }

    @Test(.timeLimit(.minutes(1)))
    func refreshThresholdUsesRemainingTTL() throws {
        let clock = Mutex(Int64(0))
        let host = try Host(rawValue: "agent.example.com")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let badge = Badge(host: host, status: .active, serverFingerprint: fingerprint)
        let configuration = try Cache.Configuration(defaultTTL: .seconds(10), refreshThreshold: .seconds(3))
        let cache = Cache(configuration: configuration, monotonicNanoseconds: {
            clock.withLock { $0 }
        })

        cache.insert(badge, for: host)
        let entry = try #require(cache.entry(for: host))

        clock.withLock { $0 = 6_999_999_999 }
        #expect(!cache.shouldRefresh(entry))

        clock.withLock { $0 = 7_000_000_000 }
        #expect(cache.shouldRefresh(entry))
    }

    @Test(.timeLimit(.minutes(1)))
    func evictsOldestEntryWhenCapacityIsExceeded() throws {
        let clock = Mutex(Int64(0))
        let configuration = try Cache.Configuration(maxEntries: 2, defaultTTL: .seconds(100))
        let cache = Cache(configuration: configuration, monotonicNanoseconds: {
            clock.withLock { $0 }
        })
        let firstHost = try Host(rawValue: "first.example.com")
        let secondHost = try Host(rawValue: "second.example.com")
        let thirdHost = try Host(rawValue: "third.example.com")

        cache.insert(try badge(for: firstHost, bytes: [1]), for: firstHost)
        clock.withLock { $0 = 1 }
        cache.insert(try badge(for: secondHost, bytes: [2]), for: secondHost)
        clock.withLock { $0 = 2 }
        cache.insert(try badge(for: thirdHost, bytes: [3]), for: thirdHost)

        #expect(cache.entry(for: firstHost) == nil)
        #expect(cache.entry(for: secondHost) != nil)
        #expect(cache.entry(for: thirdHost) != nil)
        #expect(cache.count == 2)
    }

    @Test(.timeLimit(.minutes(1)))
    func staleEntryIsUnavailableBeyondRequestedStaleness() throws {
        let clock = Mutex(Int64(0))
        let host = try Host(rawValue: "agent.example.com")
        let configuration = try Cache.Configuration(defaultTTL: .zero)
        let cache = Cache(configuration: configuration, monotonicNanoseconds: {
            clock.withLock { $0 }
        })

        cache.insert(try badge(for: host, bytes: [1, 2, 3]), for: host)
        clock.withLock { $0 = 20_000_000_000 }

        #expect(cache.staleEntry(for: host, maximumStaleness: .seconds(10)) == nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func cleanupRemovesExpiredEntriesBeyondRetentionOnInsert() throws {
        let clock = Mutex(Int64(0))
        let configuration = try Cache.Configuration(defaultTTL: .zero, staleRetention: .seconds(1))
        let cache = Cache(configuration: configuration, monotonicNanoseconds: {
            clock.withLock { $0 }
        })
        let expiredHost = try Host(rawValue: "expired.example.com")
        let freshHost = try Host(rawValue: "fresh.example.com")

        cache.insert(try badge(for: expiredHost, bytes: [1]), for: expiredHost)
        clock.withLock { $0 = 2_000_000_000 }
        cache.insert(try badge(for: freshHost, bytes: [2]), for: freshHost)

        #expect(cache.staleEntry(for: expiredHost, maximumStaleness: .seconds(10)) == nil)
        #expect(cache.staleEntry(for: freshHost, maximumStaleness: .seconds(1)) != nil)
        #expect(cache.count == 1)
    }

    private func badge(for host: Host, bytes: [UInt8]) throws -> Badge {
        let fingerprint = try Fingerprint.sha256(bytes: bytes)
        return Badge(host: host, status: .active, serverFingerprint: fingerprint)
    }
}
