import CryptoKit
import Foundation

public enum Crypto {
    public struct P256KeyGenerator: KeyGenerating {
        public init() {}

        public func p256SigningKey() throws -> P256.Signing.PrivateKey {
            P256.Signing.PrivateKey()
        }
    }

    public struct P256Signer: Signing {
        public init() {}

        public func sign(_ data: Data, privateKey: P256.Signing.PrivateKey) throws -> Data {
            try privateKey.signature(for: data).rawRepresentation
        }
    }

    public struct UnsupportedCSRGenerator: CSRGenerating {
        public init() {}

        public func serverCSR(host: Host, privateKeyPEM: String) throws -> String {
            throw CryptoError("CSR generation is not available in this build")
        }

        public func identityCSR(name: Name, privateKeyPEM: String) throws -> String {
            throw CryptoError("CSR generation is not available in this build")
        }
    }
}
