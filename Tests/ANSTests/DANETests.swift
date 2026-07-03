import Testing
import ANS

@Suite("DANE")
struct DANETests {
    @Test(.timeLimit(.minutes(1)))
    func verifiesFullCertificateSHA256Record() throws {
        let der: [UInt8] = [1, 2, 3, 4, 5]
        let fingerprint = try Fingerprint.sha256(bytes: der)
        let certificate = CertificateIdentity(
            commonName: "agent.example.com",
            dnsNames: ["agent.example.com"],
            fingerprint: fingerprint,
            derBytes: der
        )
        let record = TLSARecord(
            usage: .domainIssuedCertificate,
            selector: .fullCertificate,
            matchingType: .sha256,
            certificateAssociationData: fingerprint.bytes,
            dnssecSecure: true
        )

        let result = DANE.verify(certificate: certificate, records: [record], policy: .required)

        #expect(result.isAcceptable(for: .required))
    }
}
