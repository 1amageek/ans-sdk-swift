public struct TransparencyAudit: Sendable, Hashable {
    public let records: [Badge]
    public let pagination: Page?

    public init(records: [Badge], pagination: Page? = nil) {
        self.records = records
        self.pagination = pagination
    }
}

#if !hasFeature(Embedded)
extension TransparencyAudit: Codable {}
#endif
