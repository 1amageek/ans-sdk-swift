import CryptoKit
import Foundation

public protocol Signing: Sendable {
    func sign(_ data: Data, privateKey: P256.Signing.PrivateKey) throws -> Data
}
