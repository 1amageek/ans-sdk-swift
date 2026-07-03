import Crypto

public protocol KeyGenerating: Sendable {
    func p256() -> KeyPair
    func p384() -> KeyPair
    func p521() -> KeyPair
}

public struct KeyGenerator: KeyGenerating, Sendable {
    public init() {}

    public func p256() -> KeyPair {
        KeyPair(privateKey: P256.Signing.PrivateKey())
    }

    public func p384() -> KeyPair {
        KeyPair(privateKey: P384.Signing.PrivateKey())
    }

    public func p521() -> KeyPair {
        KeyPair(privateKey: P521.Signing.PrivateKey())
    }
}
