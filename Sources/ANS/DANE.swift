import Foundation

public enum DANE {
    public struct Verification: Sendable, Hashable {
        public let matched: Bool
        public let dnssecSecure: Bool

        public init(matched: Bool, dnssecSecure: Bool) {
            self.matched = matched
            self.dnssecSecure = dnssecSecure
        }
    }

    public static func verify(certificate: Certificate, records: [TLSA], requireDNSSEC: Bool) -> Verification {
        let fingerprint = Fingerprint.sha256(der: certificate.der)
        for record in records {
            guard record.usage == 3, record.selector == 0, record.matchingType == 1 else {
                continue
            }
            guard !requireDNSSEC || record.dnssecSecure else {
                continue
            }
            if record.certificateAssociationData == fingerprint.digest {
                return Verification(matched: true, dnssecSecure: record.dnssecSecure)
            }
        }
        return Verification(matched: false, dnssecSecure: records.contains(where: \.dnssecSecure))
    }
}
