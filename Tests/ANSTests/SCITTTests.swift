import CryptoKit
import Foundation
import XCTest
import ANS

final class SCITTTests: XCTestCase {
    func testSCITTVerificationChecksMerkleProofAndSignature() throws {
        let payload = Data("payload".utf8)
        let leaf = ANS::Proof.leafHash(payload: payload)
        let proof = ANS::Proof(treeSize: 1, leafIndex: 0, leafHash: leaf, path: [], rootHash: leaf)
        let privateKey = P256.Signing.PrivateKey()
        let signedBytes = Data("signed".utf8)
        let signature = try privateKey.signature(for: signedBytes).rawRepresentation
        let rootKey = ANS::RootKey(
            origin: "test",
            keyID: Data([0, 0, 0, 1]),
            spkiDER: privateKey.publicKey.derRepresentation,
            rawLine: ""
        )
        let evidence = ANS::SCITT.Evidence(
            receipt: ANS::Receipt(bytes: Data([1])),
            payload: payload,
            proof: proof,
            rootKey: rootKey,
            signedBytes: signedBytes,
            signature: signature
        )

        let verification = try ANS::SCITT.verify(evidence)

        XCTAssertTrue(verification.verified)
    }
}
