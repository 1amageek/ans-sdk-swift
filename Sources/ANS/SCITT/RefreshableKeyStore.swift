#if !hasFeature(Embedded)
import Synchronization

public final class SCITTRefreshableKeyStore: SCITTKeyLookup, Sendable {
    public struct Configuration: Sendable, Hashable {
        public static let defaults = Configuration(onDemandCooldown: .seconds(300))

        public let onDemandCooldown: Duration

        public init(onDemandCooldown: Duration = .seconds(300)) {
            self.onDemandCooldown = onDemandCooldown < .zero ? .zero : onDemandCooldown
        }
    }

    private struct State: Sendable {
        var store: SCITTKeyStore
        var lastRefreshedAt: Int64?
    }

    private let artifacts: (any SCITTArtifactFetching)?
    private let configuration: Configuration
    private let currentUnixTime: @Sendable () -> Int64
    private let state: Mutex<State>

    public var count: Int {
        state.withLock { $0.store.count }
    }

    public var lastRefreshedAt: Int64? {
        state.withLock { $0.lastRefreshedAt }
    }

    public init(
        initial: SCITTKeyStore,
        artifacts: any SCITTArtifactFetching,
        configuration: Configuration = .defaults,
        currentUnixTime: @escaping @Sendable () -> Int64 = SCITTClock.unixTime
    ) {
        self.artifacts = artifacts
        self.configuration = configuration
        self.currentUnixTime = currentUnixTime
        self.state = Mutex(State(store: initial, lastRefreshedAt: nil))
    }

    public init(
        static initial: SCITTKeyStore,
        currentUnixTime: @escaping @Sendable () -> Int64 = SCITTClock.unixTime
    ) {
        self.artifacts = nil
        self.configuration = .defaults
        self.currentUnixTime = currentUnixTime
        self.state = Mutex(State(store: initial, lastRefreshedAt: nil))
    }

    public func key(for keyID: [UInt8]) throws(SCITTError) -> TrustedSCITTKey {
        let result = state.withLock { state in
            do {
                return Result<TrustedSCITTKey, SCITTError>.success(try state.store.key(for: keyID))
            } catch let error as SCITTError {
                return Result<TrustedSCITTKey, SCITTError>.failure(error)
            } catch {
                return Result<TrustedSCITTKey, SCITTError>.failure(.invalidToken("\(error)"))
            }
        }
        return try result.get()
    }

    public func snapshot() -> SCITTKeyStore {
        state.withLock { $0.store }
    }

    @discardableResult
    public func refreshIfCooldownElapsed() async throws(any Error) -> Bool {
        guard artifacts != nil else {
            return false
        }

        let shouldRefresh = state.withLock { state in
            guard let lastRefreshedAt = state.lastRefreshedAt else {
                return true
            }
            let elapsed = currentUnixTime() - lastRefreshedAt
            return elapsed >= SCITTClock.seconds(from: configuration.onDemandCooldown)
        }
        guard shouldRefresh else {
            return false
        }

        try await refreshNow()
        return true
    }

    public func refreshNow() async throws(any Error) {
        guard let artifacts else {
            return
        }
        let rootKeys = try await artifacts.rootKeys()
        let now = currentUnixTime()
        state.withLock { state in
            let (merged, _) = state.store.merging(rootKeys: rootKeys)
            state.store = merged
            state.lastRefreshedAt = now
        }
    }

    public func startBackgroundRefresh(interval: Duration = .seconds(86_400)) -> SCITTRefreshHandle {
        let task = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: interval)
                } catch {
                    return
                }
                guard !Task.isCancelled else {
                    return
                }
                do {
                    try await self?.refreshNow()
                } catch {
                    continue
                }
            }
        }
        return SCITTRefreshHandle(task: task)
    }
}
#endif
