import Foundation

extension Data {
    var ansTestHexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
