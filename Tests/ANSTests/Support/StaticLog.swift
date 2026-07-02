import ANS
import Foundation

struct StaticLog: ANS::TransparencyLog {
    let badge: ANS::Badge

    func badge(for agent: ANS::Agent.ID) async throws -> ANS::Badge {
        badge
    }

    func badge(at url: URL) async throws -> ANS::Badge {
        badge
    }

    func audit(for agent: ANS::Agent.ID, page: ANS::Page?) async throws -> ANS::Audit {
        ANS::Audit(events: [])
    }

    func receipt(for agent: ANS::Agent.ID) async throws -> ANS::Receipt {
        ANS::Receipt(bytes: Data([1]))
    }

    func statusToken(for agent: ANS::Agent.ID) async throws -> ANS::Token {
        ANS::Token(bytes: Data([1]))
    }

    func checkpoint() async throws -> ANS::Checkpoint {
        ANS::Checkpoint(origin: "test", treeSize: 0, rootHash: Data(), signature: Data())
    }

    func checkpointHistory(page: ANS::Page?) async throws -> [ANS::Checkpoint] {
        []
    }

    func schema(version: String) async throws -> Data {
        Data()
    }

    func rootKeys() async throws -> [ANS::RootKey] {
        []
    }
}
