public struct CSR: Sendable, Hashable, Identifiable {
    public enum Status: String, Sendable, Hashable {
        case pending = "PENDING"
        case signed = "SIGNED"
        case rejected = "REJECTED"
    }

    public let id: String
    public let kind: Certificate.Kind
    public let status: Status
    public let submittedAt: String?
    public let updatedAt: String?
    public let failureReason: String?

    public init(
        id: String,
        kind: Certificate.Kind,
        status: Status,
        submittedAt: String? = nil,
        updatedAt: String? = nil,
        failureReason: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.status = status
        self.submittedAt = submittedAt
        self.updatedAt = updatedAt
        self.failureReason = failureReason
    }
}

public struct CSRSubmission: Sendable, Hashable {
    public let csrID: String
    public let message: String?

    public init(csrID: String, message: String? = nil) {
        self.csrID = csrID
        self.message = message
    }
}

#if !hasFeature(Embedded)
extension CSR.Status: Codable {}
extension CSR: Codable {}
extension CSRSubmission: Codable {}
#endif
