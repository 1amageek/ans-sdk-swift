import Foundation

public protocol Transport: Sendable {
    func send(_ request: Request) async throws -> Response
}
