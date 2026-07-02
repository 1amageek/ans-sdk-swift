import Foundation

public struct TLSA: Sendable, Hashable, Codable {
    public let usage: Int
    public let selector: Int
    public let matchingType: Int
    public let certificateAssociationData: Data
    public let dnssecSecure: Bool

    public init(usage: Int, selector: Int, matchingType: Int, certificateAssociationData: Data, dnssecSecure: Bool) {
        self.usage = usage
        self.selector = selector
        self.matchingType = matchingType
        self.certificateAssociationData = certificateAssociationData
        self.dnssecSecure = dnssecSecure
    }
}
