import ANS
import Foundation

struct StaticResolver: ANS::Resolving {
    let txtRecords: [String: [String]]
    let tlsaRecords: [String: [ANS::TLSA]]

    init(txtRecords: [String: [String]] = [:], tlsaRecords: [String: [ANS::TLSA]] = [:]) {
        self.txtRecords = txtRecords
        self.tlsaRecords = tlsaRecords
    }

    func txt(_ name: String) async throws -> [String] {
        txtRecords[name] ?? []
    }

    func tlsa(_ name: String) async throws -> [ANS::TLSA] {
        tlsaRecords[name] ?? []
    }

    func serviceBinding(_ host: ANS::Host) async throws -> [ANS::ServiceBinding] {
        []
    }
}
