import CryptoKit
import Foundation
import Testing
import ANS

@Test(.timeLimit(.minutes(1)))
func scittVerificationChecksMerkleProofAndSignature() throws {
    let payload = Data("payload".utf8)
    let leaf = Proof.leafHash(payload: payload)
    let proof = Proof(treeSize: 1, leafIndex: 0, leafHash: leaf, path: [], rootHash: leaf)
    let privateKey = P256.Signing.PrivateKey()
    let signedBytes = Data("signed".utf8)
    let signature = try privateKey.signature(for: signedBytes).rawRepresentation
    let rootKey = RootKey(
        origin: "test",
        keyID: Data([0, 0, 0, 1]),
        spkiDER: privateKey.publicKey.derRepresentation,
        rawLine: ""
    )
    let evidence = SCITT.Evidence(
        receipt: Receipt(bytes: Data([1])),
        payload: payload,
        proof: proof,
        rootKey: rootKey,
        signedBytes: signedBytes,
        signature: signature
    )

    let verification = try SCITT.verify(evidence)

    #expect(verification.verified)
}

@Test(.timeLimit(.minutes(1)))
func statusTokenVerificationChecksSignature() throws {
    let privateKey = P256.Signing.PrivateKey()
    let signedBytes = Data("status".utf8)
    let signature = try privateKey.signature(for: signedBytes).rawRepresentation
    let rootKey = RootKey(
        origin: "test",
        keyID: Data([0, 0, 0, 1]),
        spkiDER: privateKey.publicKey.derRepresentation,
        rawLine: ""
    )
    let evidence = SCITT.TokenEvidence(
        token: Token(bytes: Data([1])),
        rootKey: rootKey,
        signedBytes: signedBytes,
        signature: signature
    )

    #expect(try SCITT.verifyStatusToken(evidence))
}

@Test(.timeLimit(.minutes(1)))
func proofUsesRFC6962InternalNodePrefix() {
    let left = Proof.leafHash(payload: Data("left".utf8))
    let right = Proof.leafHash(payload: Data("right".utf8))
    let root = Proof.internalHash(left: left, right: right)
    let proof = Proof(treeSize: 2, leafIndex: 0, leafHash: left, path: [right], rootHash: root)

    #expect(proof.verifiesLeafHash())
}
