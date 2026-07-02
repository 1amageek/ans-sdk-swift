import CryptoKit
import Foundation
import Testing
import ANS

@Test(.timeLimit(.minutes(1)))
func scittVerificationChecksMerkleProofAndSignature() throws {
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

    #expect(verification.verified)
}

@Test(.timeLimit(.minutes(1)))
func statusTokenVerificationChecksSignature() throws {
    let privateKey = P256.Signing.PrivateKey()
    let signedBytes = Data("status".utf8)
    let signature = try privateKey.signature(for: signedBytes).rawRepresentation
    let rootKey = ANS::RootKey(
        origin: "test",
        keyID: Data([0, 0, 0, 1]),
        spkiDER: privateKey.publicKey.derRepresentation,
        rawLine: ""
    )
    let evidence = ANS::SCITT.TokenEvidence(
        token: ANS::Token(bytes: Data([1])),
        rootKey: rootKey,
        signedBytes: signedBytes,
        signature: signature
    )

    #expect(try ANS::SCITT.verifyStatusToken(evidence))
}

@Test(.timeLimit(.minutes(1)))
func proofUsesRFC6962InternalNodePrefix() {
    let left = ANS::Proof.leafHash(payload: Data("left".utf8))
    let right = ANS::Proof.leafHash(payload: Data("right".utf8))
    let root = ANS::Proof.internalHash(left: left, right: right)
    let proof = ANS::Proof(treeSize: 2, leafIndex: 0, leafHash: left, path: [right], rootHash: root)

    #expect(proof.verifiesLeafHash())
}
