public enum DANE {
    public enum Result: Sendable, Hashable {
        case verified(TLSARecord)
        case noRecords
        case mismatch(recordsChecked: Int)
        case dnssecFailed
        case skipped

        public func isAcceptable(for policy: DANEPolicy) -> Bool {
            switch (self, policy) {
            case (.verified, _), (.skipped, _):
                return true
            case (.noRecords, .validateIfPresent):
                return true
            case (.noRecords, .disabled):
                return true
            default:
                return false
            }
        }
    }

    public static func verify(
        certificate: CertificateIdentity,
        records: [TLSARecord],
        policy: DANEPolicy
    ) -> Result {
        guard policy.shouldVerify else {
            return .skipped
        }
        guard !records.isEmpty else {
            return .noRecords
        }

        var checked = 0
        for record in records {
            guard !policy.isRequired || record.dnssecSecure else {
                return .dnssecFailed
            }
            guard let matches = record.matches(certificate: certificate) else {
                continue
            }
            checked += 1
            if matches {
                return .verified(record)
            }
        }
        return .mismatch(recordsChecked: checked)
    }
}
