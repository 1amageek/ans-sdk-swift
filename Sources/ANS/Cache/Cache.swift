#if !hasFeature(Embedded)
import Synchronization
#endif

public final class Cache {
    public struct Configuration: Sendable, Hashable {
        public static let defaults = Configuration(
            uncheckedMaxEntries: 1000,
            defaultTTL: .seconds(300),
            refreshThreshold: .seconds(60),
            staleRetention: .seconds(600)
        )

        public let maxEntries: Int
        public let defaultTTL: Duration
        public let refreshThreshold: Duration
        public let staleRetention: Duration

        public init(
            maxEntries: Int = 1000,
            defaultTTL: Duration = .seconds(300),
            refreshThreshold: Duration = .seconds(60),
            staleRetention: Duration = .seconds(600)
        ) throws(ConfigurationError) {
            guard maxEntries >= 0 else {
                throw .negativeMaxEntries
            }
            guard defaultTTL >= .zero else {
                throw .negativeDefaultTTL
            }
            guard refreshThreshold >= .zero else {
                throw .negativeRefreshThreshold
            }
            guard staleRetention >= .zero else {
                throw .negativeStaleRetention
            }

            self.maxEntries = maxEntries
            self.defaultTTL = defaultTTL
            self.refreshThreshold = refreshThreshold
            self.staleRetention = staleRetention
        }

        private init(
            uncheckedMaxEntries maxEntries: Int,
            defaultTTL: Duration,
            refreshThreshold: Duration,
            staleRetention: Duration
        ) {
            self.maxEntries = maxEntries
            self.defaultTTL = defaultTTL
            self.refreshThreshold = refreshThreshold
            self.staleRetention = staleRetention
        }
    }

    public enum ConfigurationError: Error, Sendable, Equatable {
        case negativeMaxEntries
        case negativeDefaultTTL
        case negativeRefreshThreshold
        case negativeStaleRetention
    }

    public struct Entry: Sendable, Hashable {
        public let badge: Badge
        public let host: Host
        public let version: Version?
        public let fetchedAtNanoseconds: Int64
        public let expiresAtNanoseconds: Int64

        public func isExpired(at monotonicNanoseconds: Int64) -> Bool {
            monotonicNanoseconds >= expiresAtNanoseconds
        }

        public func remainingTTL(at monotonicNanoseconds: Int64) -> Duration {
            if monotonicNanoseconds >= expiresAtNanoseconds {
                return .zero
            }
            return .nanoseconds(expiresAtNanoseconds - monotonicNanoseconds)
        }

        public func shouldRefresh(threshold: Duration, at monotonicNanoseconds: Int64) -> Bool {
            remainingTTL(at: monotonicNanoseconds) <= threshold
        }

        fileprivate func isWithinStaleness(
            _ maximumStaleness: Duration,
            at monotonicNanoseconds: Int64
        ) -> Bool {
            monotonicNanoseconds <= Cache.adding(
                expiresAtNanoseconds,
                Cache.nanoseconds(from: maximumStaleness)
            )
        }
    }

    private enum StorageKey: Sendable, Hashable {
        case host(Host)
        case hostVersion(Host, Version)
    }

    private struct State: Sendable {
        var entries: [StorageKey: Entry] = [:]
        var versionsByHost: [Host: Set<Version>] = [:]
    }

    private let configuration: Configuration
    private let monotonicNanoseconds: @Sendable () -> Int64

#if hasFeature(Embedded)
    private var storage = State()
#else
    private let storage: Mutex<State>
#endif

    public var count: Int {
        readStorage { state in
            state.entries.count
        }
    }

    public convenience init(configuration: Configuration = .defaults) {
        self.init(configuration: configuration, monotonicNanoseconds: Cache.defaultMonotonicNanoseconds())
    }

    public init(
        configuration: Configuration,
        monotonicNanoseconds: @escaping @Sendable () -> Int64
    ) {
        self.configuration = configuration
        self.monotonicNanoseconds = monotonicNanoseconds
#if !hasFeature(Embedded)
        self.storage = Mutex(State())
#endif
    }

    public func entry(for host: Host) -> Entry? {
        entry(for: .host(host), at: monotonicNanoseconds())
    }

    public func entry(for host: Host, version: Version) -> Entry? {
        entry(for: .hostVersion(host, version), at: monotonicNanoseconds())
    }

    public func entries(for host: Host) -> [Entry] {
        let instant = monotonicNanoseconds()
        return readStorage { state in
            entries(for: host, in: state, at: instant, includeStale: false, maximumStaleness: nil)
        }
    }

    public func staleEntry(for host: Host, maximumStaleness: Duration) -> Entry? {
        staleEntry(for: .host(host), maximumStaleness: maximumStaleness, at: monotonicNanoseconds())
    }

    public func staleEntry(for host: Host, version: Version, maximumStaleness: Duration) -> Entry? {
        staleEntry(
            for: .hostVersion(host, version),
            maximumStaleness: maximumStaleness,
            at: monotonicNanoseconds()
        )
    }

    public func staleEntries(for host: Host, maximumStaleness: Duration) -> [Entry] {
        let instant = monotonicNanoseconds()
        return readStorage { state in
            entries(for: host, in: state, at: instant, includeStale: true, maximumStaleness: maximumStaleness)
        }
    }

    public func insert(_ badge: Badge, for host: Host) {
        let instant = monotonicNanoseconds()
        updateStorage { state in
            let entry = Entry(
                badge: badge,
                host: host,
                version: nil,
                fetchedAtNanoseconds: instant,
                expiresAtNanoseconds: Self.adding(instant, Self.nanoseconds(from: configuration.defaultTTL))
            )
            state.entries[.host(host)] = entry

            if let version = badge.name?.version, badge.name?.host == host {
                insert(badge, host: host, version: version, fetchedAt: instant, into: &state)
            }

            cleanup(&state, at: instant)
        }
    }

    public func insert(_ badge: Badge, for host: Host, version: Version) {
        let instant = monotonicNanoseconds()
        updateStorage { state in
            insert(badge, host: host, version: version, fetchedAt: instant, into: &state)
            cleanup(&state, at: instant)
        }
    }

    public func setVersions(_ versions: [Version], for host: Host) {
        updateStorage { state in
            state.versionsByHost[host] = Set(versions)
        }
    }

    public func invalidate(host: Host) {
        updateStorage { state in
            remove(.host(host), from: &state)
            guard let versions = state.versionsByHost.removeValue(forKey: host) else {
                return
            }
            for version in versions {
                remove(.hostVersion(host, version), from: &state)
            }
        }
    }

    public func invalidate(host: Host, version: Version) {
        updateStorage { state in
            remove(.hostVersion(host, version), from: &state)
        }
    }

    public func removeAll() {
        updateStorage { state in
            state.entries.removeAll()
            state.versionsByHost.removeAll()
        }
    }

    public func shouldRefresh(_ entry: Entry) -> Bool {
        entry.shouldRefresh(threshold: configuration.refreshThreshold, at: monotonicNanoseconds())
    }

    private func entry(for key: StorageKey, at monotonicNanoseconds: Int64) -> Entry? {
        readStorage { state in
            guard let entry = state.entries[key], !entry.isExpired(at: monotonicNanoseconds) else {
                return nil
            }
            return entry
        }
    }

    private func staleEntry(
        for key: StorageKey,
        maximumStaleness: Duration,
        at monotonicNanoseconds: Int64
    ) -> Entry? {
        guard maximumStaleness >= .zero else {
            return nil
        }

        return readStorage { state in
            guard let entry = state.entries[key],
                  entry.isWithinStaleness(maximumStaleness, at: monotonicNanoseconds) else {
                return nil
            }
            return entry
        }
    }

    private func entries(
        for host: Host,
        in state: State,
        at monotonicNanoseconds: Int64,
        includeStale: Bool,
        maximumStaleness: Duration?
    ) -> [Entry] {
        var result: [Entry] = []

        if let entry = state.entries[.host(host)],
           includes(entry, at: monotonicNanoseconds, includeStale: includeStale, maximumStaleness: maximumStaleness) {
            result.append(entry)
        }

        let versions = state.versionsByHost[host, default: []].sorted()
        for version in versions {
            guard let entry = state.entries[.hostVersion(host, version)] else {
                continue
            }
            guard includes(
                entry,
                at: monotonicNanoseconds,
                includeStale: includeStale,
                maximumStaleness: maximumStaleness
            ) else {
                continue
            }
            result.append(entry)
        }

        return result
    }

    private func includes(
        _ entry: Entry,
        at monotonicNanoseconds: Int64,
        includeStale: Bool,
        maximumStaleness: Duration?
    ) -> Bool {
        if !includeStale {
            return !entry.isExpired(at: monotonicNanoseconds)
        }
        guard let maximumStaleness, maximumStaleness >= .zero else {
            return false
        }
        return entry.isWithinStaleness(maximumStaleness, at: monotonicNanoseconds)
    }

    private func insert(
        _ badge: Badge,
        host: Host,
        version: Version,
        fetchedAt: Int64,
        into state: inout State
    ) {
        let entry = Entry(
            badge: badge,
            host: host,
            version: version,
            fetchedAtNanoseconds: fetchedAt,
            expiresAtNanoseconds: Self.adding(fetchedAt, Self.nanoseconds(from: configuration.defaultTTL))
        )
        state.entries[.hostVersion(host, version)] = entry
        state.versionsByHost[host, default: []].insert(version)
    }

    private func cleanup(_ state: inout State, at monotonicNanoseconds: Int64) {
        for (key, entry) in state.entries where monotonicNanoseconds > Self.adding(
            entry.expiresAtNanoseconds,
            Self.nanoseconds(from: configuration.staleRetention)
        ) {
            remove(key, from: &state)
        }

        guard state.entries.count > configuration.maxEntries else {
            return
        }

        let overflow = state.entries.count - configuration.maxEntries
        let keys = state.entries
            .sorted { lhs, rhs in lhs.value.fetchedAtNanoseconds < rhs.value.fetchedAtNanoseconds }
            .prefix(overflow)
            .map { element in element.key }

        for key in keys {
            remove(key, from: &state)
        }
    }

    private func remove(_ key: StorageKey, from state: inout State) {
        state.entries.removeValue(forKey: key)
        guard case .hostVersion(let host, let version) = key else {
            return
        }

        state.versionsByHost[host]?.remove(version)
        if state.versionsByHost[host]?.isEmpty == true {
            state.versionsByHost.removeValue(forKey: host)
        }
    }

#if hasFeature(Embedded)
    private func readStorage<Value>(_ body: (State) -> Value) -> Value {
        body(storage)
    }

    private func updateStorage<Value>(_ body: (inout State) -> Value) -> Value {
        body(&storage)
    }

    private static func defaultMonotonicNanoseconds() -> @Sendable () -> Int64 {
        { 0 }
    }
#else
    private func readStorage<Value>(_ body: (State) -> Value) -> Value {
        storage.withLock { state in
            body(state)
        }
    }

    private func updateStorage<Value>(_ body: (inout State) -> Value) -> Value {
        storage.withLock { state in
            body(&state)
        }
    }

    private static func defaultMonotonicNanoseconds() -> @Sendable () -> Int64 {
        let clock = ContinuousClock()
        let origin = clock.now
        return {
            nanoseconds(from: origin.duration(to: clock.now))
        }
    }
#endif

    fileprivate static func nanoseconds(from duration: Duration) -> Int64 {
        let components = duration.components
        let (secondsNanoseconds, secondsOverflow) = components.seconds.multipliedReportingOverflow(
            by: 1_000_000_000
        )
        if secondsOverflow {
            return components.seconds >= 0 ? Int64.max : Int64.min
        }

        let attosecondNanoseconds = components.attoseconds / 1_000_000_000
        let (total, overflow) = secondsNanoseconds.addingReportingOverflow(attosecondNanoseconds)
        if overflow {
            return secondsNanoseconds >= 0 ? Int64.max : Int64.min
        }
        return total
    }

    fileprivate static func adding(_ lhs: Int64, _ rhs: Int64) -> Int64 {
        let (sum, overflow) = lhs.addingReportingOverflow(rhs)
        if overflow {
            return rhs >= 0 ? Int64.max : Int64.min
        }
        return sum
    }
}

#if !hasFeature(Embedded)
extension Cache: Caching {}
#endif
