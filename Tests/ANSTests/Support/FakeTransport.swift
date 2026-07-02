import ANS
import Foundation
import Synchronization

final class FakeTransport: ANS::Transport {
    private struct State: Sendable {
        var lastRequest: ANS::Request?
    }

    private let response: ANS::Response
    private let state = Mutex(State())

    init(response: ANS::Response) {
        self.response = response
    }

    func send(_ request: ANS::Request) async throws -> ANS::Response {
        state.withLock { state in
            state.lastRequest = request
        }
        return response
    }

    func recordedRequest() -> ANS::Request? {
        state.withLock { state in
            state.lastRequest
        }
    }
}
