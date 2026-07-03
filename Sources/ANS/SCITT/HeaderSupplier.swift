#if !hasFeature(Embedded)
public struct SCITTOutgoingHeaders: Sendable, Hashable {
    public let receiptBase64: String?
    public let statusTokenBase64: String?

    public var isEmpty: Bool {
        receiptBase64 == nil && statusTokenBase64 == nil
    }

    public init(receiptBase64: String? = nil, statusTokenBase64: String? = nil) {
        self.receiptBase64 = receiptBase64
        self.statusTokenBase64 = statusTokenBase64
    }

    public init(receipt: [UInt8], statusToken: [UInt8]) {
        self.receiptBase64 = receipt.isEmpty ? nil : Base64.encode(receipt)
        self.statusTokenBase64 = statusToken.isEmpty ? nil : Base64.encode(statusToken)
    }

    public func httpHeaders() -> [String: String] {
        var headers: [String: String] = [:]
        if let receiptBase64 {
            headers[SCITTHeaders.receiptHeaderName] = receiptBase64
        }
        if let statusTokenBase64 {
            headers[SCITTHeaders.statusTokenHeaderName] = statusTokenBase64
        }
        return headers
    }
}

public final class SCITTRefreshHandle: Sendable {
    private let task: Task<Void, Never>

    init(task: Task<Void, Never>) {
        self.task = task
    }

    public func cancel() {
        task.cancel()
    }

    deinit {
        task.cancel()
    }
}

public actor SCITTHeaderSupplier {
    public struct Configuration: Sendable, Hashable {
        public static let defaults = Configuration(
            clockSkew: .seconds(30),
            minimumRefreshInterval: .seconds(10)
        )

        public let clockSkew: Duration
        public let minimumRefreshInterval: Duration

        public init(clockSkew: Duration = .seconds(30), minimumRefreshInterval: Duration = .seconds(10)) {
            self.clockSkew = clockSkew < .zero ? .zero : clockSkew
            self.minimumRefreshInterval = minimumRefreshInterval < .zero ? .zero : minimumRefreshInterval
        }
    }

    private let agentID: Agent.ID
    private let artifacts: any SCITTArtifactFetching
    private let verifier: any SCITTVerifying
    private let configuration: Configuration
    private let currentUnixTime: @Sendable () -> Int64

    private var receipt: [UInt8] = []
    private var statusToken: [UInt8] = []
    private var tokenExpiresAt: Int64?
    private var initialized = false
    private var lastError: (any Error)?

    public init(
        agentID: Agent.ID,
        artifacts: any SCITTArtifactFetching,
        verifier: any SCITTVerifying,
        configuration: Configuration = .defaults,
        currentUnixTime: @escaping @Sendable () -> Int64 = SCITTClock.unixTime
    ) {
        self.agentID = agentID
        self.artifacts = artifacts
        self.verifier = verifier
        self.configuration = configuration
        self.currentUnixTime = currentUnixTime
    }

    public func currentHeaders() async -> SCITTOutgoingHeaders {
        if !initialized {
            do {
                try await refreshNow()
            } catch {
                lastError = error
            }
        }

        let now = currentUnixTime()
        let freshToken: [UInt8]
        if let tokenExpiresAt, now < tokenExpiresAt {
            freshToken = statusToken
        } else {
            freshToken = []
        }
        return SCITTOutgoingHeaders(receipt: receipt, statusToken: freshToken)
    }

    public func refreshNow() async throws(any Error) {
        async let receiptBytes = artifacts.receipt(agentID: agentID)
        async let tokenBytes = artifacts.statusToken(agentID: agentID)

        let fetchedReceipt: [UInt8]?
        let receiptFetchError: (any Error)?
        do {
            fetchedReceipt = try await receiptBytes
            receiptFetchError = nil
        } catch {
            fetchedReceipt = nil
            receiptFetchError = error
        }

        let fetchedToken: [UInt8]?
        let tokenFetchError: (any Error)?
        do {
            fetchedToken = try await tokenBytes
            tokenFetchError = nil
        } catch {
            fetchedToken = nil
            tokenFetchError = error
        }

        var refreshError: (any Error)?

        if let fetchedReceipt {
            do {
                _ = try await verifier.verifyReceipt(fetchedReceipt)
                receipt = fetchedReceipt
            } catch {
                refreshError = error
            }
        } else if let receiptFetchError {
            refreshError = receiptFetchError
        }

        if let fetchedToken {
            do {
                let verifiedToken = try await verifier.verifyStatusToken(fetchedToken)
                statusToken = fetchedToken
                tokenExpiresAt = verifiedToken.payload.expiresAt
            } catch {
                refreshError = error
            }
        } else if let tokenFetchError {
            refreshError = tokenFetchError
        }

        initialized = initialized || !statusToken.isEmpty
        lastError = refreshError

        if let refreshError, statusToken.isEmpty {
            throw refreshError
        }
    }

    public func healthy() -> Bool {
        initialized && lastError == nil
    }

    public func latestError() -> (any Error)? {
        lastError
    }

    public func startAutoRefresh() -> SCITTRefreshHandle {
        let task = Task { [weak self] in
            while !Task.isCancelled {
                let interval = await self?.nextRefreshInterval() ?? .seconds(10)
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
                    await self?.record(error)
                }
            }
        }
        return SCITTRefreshHandle(task: task)
    }

    private func nextRefreshInterval() -> Duration {
        guard let tokenExpiresAt else {
            return configuration.minimumRefreshInterval
        }
        let remaining = max(0, tokenExpiresAt - currentUnixTime())
        let half = remaining / 2
        let seconds = max(SCITTClock.seconds(from: configuration.minimumRefreshInterval), half)
        return .seconds(seconds)
    }

    private func record(_ error: any Error) {
        lastError = error
    }
}
#endif
