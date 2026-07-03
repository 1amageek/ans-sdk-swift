#if !hasFeature(Embedded)
public protocol Caching: Sendable {
    var count: Int { get }

    func entry(for host: Host) -> Cache.Entry?
    func entry(for host: Host, version: Version) -> Cache.Entry?
    func entries(for host: Host) -> [Cache.Entry]
    func staleEntry(for host: Host, maximumStaleness: Duration) -> Cache.Entry?
    func staleEntry(for host: Host, version: Version, maximumStaleness: Duration) -> Cache.Entry?
    func staleEntries(for host: Host, maximumStaleness: Duration) -> [Cache.Entry]
    func insert(_ badge: Badge, for host: Host)
    func insert(_ badge: Badge, for host: Host, version: Version)
    func setVersions(_ versions: [Version], for host: Host)
    func invalidate(host: Host)
    func invalidate(host: Host, version: Version)
    func removeAll()
}
#endif
