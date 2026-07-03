import Testing
import ANS

@Suite("Crypto")
struct CryptoTests {
    @Test(.timeLimit(.minutes(1)))
    func generatesP256KeyPairPEM() throws {
        let keyPair = KeyGenerator().p256()

        #expect(keyPair.privateKeyPEM.contains("BEGIN PRIVATE KEY"))
        #expect(keyPair.publicKeyPEM.contains("BEGIN PUBLIC KEY"))
        #expect(!keyPair.privateKeyDER.isEmpty)
        #expect(!keyPair.publicKeyDER.isEmpty)
    }

    @Test(.timeLimit(.minutes(1)))
    func generatesAdditionalECKeyPairs() throws {
        let generator = KeyGenerator()

        #expect(generator.p384().algorithm == .p384)
        #expect(generator.p521().algorithm == .p521)
    }

    @Test(.timeLimit(.minutes(1)))
    func serverCSRContainsDNSSubjectAlternativeName() throws {
        let host = try Host(rawValue: "agent.example.com")
        let keyPair = KeyGenerator().p256()

        let csr = try CSRGenerator().serverCSR(host: host, keyPair: keyPair)

        #expect(csr.pem.contains("BEGIN CERTIFICATE REQUEST"))
        #expect(csr.der.containsSubsequence(Array("agent.example.com".utf8)))
    }

    @Test(.timeLimit(.minutes(1)))
    func identityCSRContainsANSNameSubjectAlternativeName() throws {
        let host = try Host(rawValue: "agent.example.com")
        let name = Name(version: try Version("1.2.3"), host: host)
        let keyPair = KeyGenerator().p256()

        let csr = try CSRGenerator().identityCSR(name: name, keyPair: keyPair)

        #expect(csr.der.containsSubsequence(Array(host.rawValue.utf8)))
        #expect(csr.der.containsSubsequence(Array(name.rawValue.utf8)))
    }
}

private extension Array where Element == UInt8 {
    func containsSubsequence(_ candidate: [UInt8]) -> Bool {
        guard !candidate.isEmpty, candidate.count <= count else {
            return false
        }

        for offset in 0...(count - candidate.count) {
            if Array(self[offset..<(offset + candidate.count)]) == candidate {
                return true
            }
        }
        return false
    }
}
