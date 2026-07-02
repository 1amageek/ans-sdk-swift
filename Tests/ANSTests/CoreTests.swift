import CryptoKit
import Foundation
import XCTest
import ANS

final class CoreTests: XCTestCase {
    func testNameParsesWithModuleSelector() throws {
        let name = try ANS::Name(rawValue: "ans://v1.2.3.agent.example.com")

        XCTAssertEqual(name.version, try ANS::Version("1.2.3"))
        XCTAssertEqual(name.host, try ANS::Host(rawValue: "agent.example.com"))
        XCTAssertEqual(name.rawValue, "ans://v1.2.3.agent.example.com")
    }

    func testVersionRejectsPrereleaseAndBuildMetadata() {
        XCTAssertThrowsError(try ANS::Version("1.0.0-beta"))
        XCTAssertThrowsError(try ANS::Version("1.0.0+build"))
    }

    func testHostRejectsIPAndSingleLabel() {
        XCTAssertThrowsError(try ANS::Host(rawValue: "127.0.0.1"))
        XCTAssertThrowsError(try ANS::Host(rawValue: "localhost"))
    }

    func testWireAliasesCanonicalize() {
        XCTAssertEqual(ANS::Endpoint.ProtocolKind("HTTP_API").rawValue, "HTTP-API")
        XCTAssertEqual(ANS::Endpoint.TransportKind("STREAMABLE_HTTP").rawValue, "STREAMABLE-HTTP")
        XCTAssertEqual(ANS::Endpoint.TransportKind("JSON_RPC").rawValue, "JSON-RPC")
    }

    func testRegistrationValidatesVersionCSRPairing() throws {
        let host = try ANS::Host(rawValue: "agent.example.com")
        let endpoint = ANS::Endpoint(url: URL(string: "https://agent.example.com/mcp")!, protocolKind: .mcp)

        XCTAssertThrowsError(
            try ANS::Registration.Request(
                displayName: "Agent",
                host: host,
                endpoints: [endpoint],
                version: try ANS::Version("1.0.0")
            )
        )

        XCTAssertNoThrow(
            try ANS::Registration.Request(
                displayName: "Agent",
                host: host,
                endpoints: [endpoint],
                version: try ANS::Version("1.0.0"),
                identityCSR: "-----BEGIN CERTIFICATE REQUEST-----\n-----END CERTIFICATE REQUEST-----"
            )
        )
    }

    func testFingerprintSHA256() {
        let data = Data([0x01, 0x02, 0x03])
        let fingerprint = ANS::Fingerprint.sha256(der: data)
        let expected = Data(SHA256.hash(data: data)).ansTestHexString
        XCTAssertEqual(fingerprint.rawValue, "SHA256:\(expected)")
    }
}

private extension Data {
    var ansTestHexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
