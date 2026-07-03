#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

import Testing
import ANS

@Suite("Foundation support")
struct FoundationSupportTests {
    @Test(.timeLimit(.minutes(1)))
    func encodesAndDecodesBadgeJSON() throws {
        let host = try Host(rawValue: "agent.example.com")
        let fingerprint = try Fingerprint.sha256(bytes: [1, 2, 3])
        let badge = Badge(host: host, status: .active, serverFingerprint: fingerprint)

        let bytes = try JSON.encode(badge)
        let decoded = try JSON.decode(Badge.self, from: bytes)

        #expect(decoded == badge)
    }

    @Test(.timeLimit(.minutes(1)))
    func hashesDataFingerprint() throws {
        let data = Data([1, 2, 3])
        let fingerprint = try Fingerprint.sha256(der: data)

        #expect(fingerprint == (try Fingerprint.sha256(bytes: [1, 2, 3])))
    }
}
