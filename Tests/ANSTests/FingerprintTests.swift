import Testing
import ANS

@Suite("Fingerprint")
struct FingerprintTests {
    @Test(.timeLimit(.minutes(1)))
    func parsesCanonicalSHA256() throws {
        let raw = "SHA256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        let fingerprint = try Fingerprint(rawValue: raw)

        #expect(fingerprint.rawValue == raw)
    }

    @Test(.timeLimit(.minutes(1)))
    func hashesBytes() throws {
        let fingerprint = try Fingerprint.sha256(bytes: [UInt8]())

        #expect(fingerprint.rawValue == "SHA256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
    }
}
