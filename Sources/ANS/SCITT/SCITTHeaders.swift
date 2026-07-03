public struct SCITTHeaders: Sendable, Hashable {
    public static let receiptHeaderName = "X-SCITT-Receipt"
    public static let statusTokenHeaderName = "X-ANS-Status-Token"

    public let receipt: [UInt8]
    public let statusToken: [UInt8]

    public var isEmpty: Bool {
        receipt.isEmpty && statusToken.isEmpty
    }

    public var hasStatusToken: Bool {
        !statusToken.isEmpty
    }

    public var hasReceipt: Bool {
        !receipt.isEmpty
    }

    public var hasBoth: Bool {
        hasReceipt && hasStatusToken
    }

    public init(receipt: [UInt8] = [], statusToken: [UInt8] = []) {
        self.receipt = receipt
        self.statusToken = statusToken
    }

    public init(httpHeaders: [String: String]) throws(Base64.DecodingError) {
        let receiptValue = Self.headerValue(named: Self.receiptHeaderName, in: httpHeaders)
        let statusTokenValue = Self.headerValue(named: Self.statusTokenHeaderName, in: httpHeaders)
        let receipt: [UInt8]
        if let receiptValue {
            receipt = try Base64.decode(receiptValue)
        } else {
            receipt = []
        }
        let statusToken: [UInt8]
        if let statusTokenValue {
            statusToken = try Base64.decode(statusTokenValue)
        } else {
            statusToken = []
        }
        self.init(receipt: receipt, statusToken: statusToken)
    }

    public func httpHeaders() -> [String: String] {
        var headers: [String: String] = [:]
        if !receipt.isEmpty {
            headers[Self.receiptHeaderName] = Base64.encode(receipt)
        }
        if !statusToken.isEmpty {
            headers[Self.statusTokenHeaderName] = Base64.encode(statusToken)
        }
        return headers
    }

    private static func headerValue(named name: String, in headers: [String: String]) -> String? {
        if let value = headers[name] {
            return value
        }
        let lowercase = name.lowercased()
        for (key, value) in headers where key.lowercased() == lowercase {
            return value
        }
        return nil
    }
}

#if !hasFeature(Embedded)
extension SCITTHeaders: Codable {}
#endif
