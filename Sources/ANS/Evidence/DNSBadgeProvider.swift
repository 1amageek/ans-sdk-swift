#if !hasFeature(Embedded)
public struct DNSBadgeProvider: VersionedBadgeProviding {
    private let discovery: BadgeDiscovery
    private let transparencyLog: any TransparencyLog
    private let urlValidator: BadgeURLValidator

    public init(
        discovery: BadgeDiscovery,
        transparencyLog: any TransparencyLog,
        urlValidator: BadgeURLValidator = BadgeURLValidator()
    ) {
        self.discovery = discovery
        self.transparencyLog = transparencyLog
        self.urlValidator = urlValidator
    }

    public func badge(for host: Host) async throws(any Error) -> Badge? {
        guard let record = try await discovery.preferredRecord(for: host) else {
            return nil
        }
        guard urlValidator.validate(record.url) else {
            throw ParsingError.invalidURI(record.url.rawValue)
        }
        return try await transparencyLog.badge(at: record.url)
    }

    public func badge(for host: Host, version: Version) async throws(any Error) -> Badge? {
        guard let record = try await discovery.record(for: host, version: version) else {
            return nil
        }
        guard urlValidator.validate(record.url) else {
            throw ParsingError.invalidURI(record.url.rawValue)
        }
        return try await transparencyLog.badge(at: record.url)
    }
}
#endif
