#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif
import Crypto

public struct KeyPair: Sendable {
    public enum Algorithm: Sendable, Hashable {
        case p256
        case p384
        case p521
    }

    enum Storage: Sendable {
        case p256(P256.Signing.PrivateKey)
        case p384(P384.Signing.PrivateKey)
        case p521(P521.Signing.PrivateKey)
    }

    let storage: Storage

    public var algorithm: Algorithm {
        switch storage {
        case .p256:
            return .p256
        case .p384:
            return .p384
        case .p521:
            return .p521
        }
    }

    public var privateKeyDER: [UInt8] {
        switch storage {
        case .p256(let privateKey):
            return Array(privateKey.derRepresentation)
        case .p384(let privateKey):
            return Array(privateKey.derRepresentation)
        case .p521(let privateKey):
            return Array(privateKey.derRepresentation)
        }
    }

    public var publicKeyDER: [UInt8] {
        switch storage {
        case .p256(let privateKey):
            return Array(privateKey.publicKey.derRepresentation)
        case .p384(let privateKey):
            return Array(privateKey.publicKey.derRepresentation)
        case .p521(let privateKey):
            return Array(privateKey.publicKey.derRepresentation)
        }
    }

    public var privateKeyPEM: String {
        PEM.encode(type: "PRIVATE KEY", der: privateKeyDER)
    }

    public var publicKeyPEM: String {
        PEM.encode(type: "PUBLIC KEY", der: publicKeyDER)
    }

    public init(privateKey: P256.Signing.PrivateKey) {
        self.storage = .p256(privateKey)
    }

    public init(privateKey: P384.Signing.PrivateKey) {
        self.storage = .p384(privateKey)
    }

    public init(privateKey: P521.Signing.PrivateKey) {
        self.storage = .p521(privateKey)
    }

    func signature(for bytes: [UInt8]) throws(CryptoError) -> [UInt8] {
        do {
            switch storage {
            case .p256(let privateKey):
                return Array(try privateKey.signature(for: Data(bytes)).derRepresentation)
            case .p384(let privateKey):
                return Array(try privateKey.signature(for: Data(bytes)).derRepresentation)
            case .p521(let privateKey):
                return Array(try privateKey.signature(for: Data(bytes)).derRepresentation)
            }
        } catch {
            throw .signatureFailed
        }
    }
}
