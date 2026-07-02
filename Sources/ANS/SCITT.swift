import CryptoKit
import Foundation

public protocol SCITTVerifying: Sendable {
    func verify(badge: Badge) async throws -> Bool
}

public struct BadgeSCITTVerifier: SCITTVerifying {
    public init() {}

    public func verify(badge: Badge) async throws -> Bool {
        guard badge.receipt != nil || badge.statusToken != nil else {
            return false
        }
        if let proof = badge.proof {
            return proof.verifiesLeafHash()
        }
        return true
    }
}

public enum SCITT {
    public struct Evidence: Sendable, Hashable {
        public let receipt: Receipt
        public let payload: Data
        public let proof: Proof
        public let rootKey: RootKey
        public let signedBytes: Data
        public let signature: Data

        public init(receipt: Receipt, payload: Data, proof: Proof, rootKey: RootKey, signedBytes: Data, signature: Data) {
            self.receipt = receipt
            self.payload = payload
            self.proof = proof
            self.rootKey = rootKey
            self.signedBytes = signedBytes
            self.signature = signature
        }
    }

    public struct Verification: Sendable, Hashable {
        public let merkleVerified: Bool
        public let signatureVerified: Bool

        public var verified: Bool {
            merkleVerified && signatureVerified
        }

        public init(merkleVerified: Bool, signatureVerified: Bool) {
            self.merkleVerified = merkleVerified
            self.signatureVerified = signatureVerified
        }
    }

    public struct TokenEvidence: Sendable, Hashable {
        public let token: Token
        public let rootKey: RootKey
        public let signedBytes: Data
        public let signature: Data

        public init(token: Token, rootKey: RootKey, signedBytes: Data, signature: Data) {
            self.token = token
            self.rootKey = rootKey
            self.signedBytes = signedBytes
            self.signature = signature
        }
    }

    public static func verify(_ evidence: Evidence) throws -> Verification {
        guard !evidence.receipt.bytes.isEmpty else {
            throw CryptoError("SCITT receipt bytes are empty")
        }
        guard evidence.proof.verifies(payload: evidence.payload) else {
            throw CryptoError("SCITT Merkle proof does not verify")
        }

        let publicKey = try P256.Signing.PublicKey(derRepresentation: evidence.rootKey.spkiDER)
        let signature: P256.Signing.ECDSASignature
        if evidence.signature.count == 64 {
            signature = try P256.Signing.ECDSASignature(rawRepresentation: evidence.signature)
        } else {
            signature = try P256.Signing.ECDSASignature(derRepresentation: evidence.signature)
        }

        let signatureVerified = publicKey.isValidSignature(signature, for: evidence.signedBytes)
        guard signatureVerified else {
            throw CryptoError("SCITT ES256 signature does not verify")
        }

        return Verification(merkleVerified: true, signatureVerified: true)
    }

    public static func verifyStatusToken(_ evidence: TokenEvidence) throws -> Bool {
        guard !evidence.token.bytes.isEmpty else {
            throw CryptoError("SCITT status token bytes are empty")
        }

        let publicKey = try P256.Signing.PublicKey(derRepresentation: evidence.rootKey.spkiDER)
        let signature: P256.Signing.ECDSASignature
        if evidence.signature.count == 64 {
            signature = try P256.Signing.ECDSASignature(rawRepresentation: evidence.signature)
        } else {
            signature = try P256.Signing.ECDSASignature(derRepresentation: evidence.signature)
        }

        guard publicKey.isValidSignature(signature, for: evidence.signedBytes) else {
            throw CryptoError("SCITT status token signature does not verify")
        }
        return true
    }
}
