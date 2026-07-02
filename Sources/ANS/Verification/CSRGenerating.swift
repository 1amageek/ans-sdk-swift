import Foundation

public protocol CSRGenerating: Sendable {
    func serverCSR(host: Host, privateKeyPEM: String) throws -> String
    func identityCSR(name: Name, privateKeyPEM: String) throws -> String
}
