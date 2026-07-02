import CryptoKit
import Foundation

public protocol KeyGenerating: Sendable {
    func p256SigningKey() throws -> P256.Signing.PrivateKey
}
