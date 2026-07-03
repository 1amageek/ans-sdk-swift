import Testing
import ANS

@Suite("SCITTHeaders")
struct SCITTHeadersTests {
    @Test(.timeLimit(.minutes(1)))
    func roundTripsHTTPHeaderValuesAsBase64() throws {
        let headers = SCITTHeaders(receipt: [1, 2, 3], statusToken: [4, 5, 6])

        let parsed = try SCITTHeaders(httpHeaders: headers.httpHeaders())

        #expect(parsed.receipt == [1, 2, 3])
        #expect(parsed.statusToken == [4, 5, 6])
        #expect(parsed.hasReceipt)
        #expect(parsed.hasStatusToken)
        #expect(parsed.hasBoth)
    }

    @Test(.timeLimit(.minutes(1)))
    func statusTokenOnlyIsValidMinimumHeaderSet() throws {
        let headers = SCITTHeaders(statusToken: [4, 5, 6])

        let parsed = try SCITTHeaders(httpHeaders: headers.httpHeaders())

        #expect(parsed.receipt.isEmpty)
        #expect(parsed.statusToken == [4, 5, 6])
        #expect(!parsed.hasReceipt)
        #expect(parsed.hasStatusToken)
        #expect(!parsed.hasBoth)
    }

    @Test(.timeLimit(.minutes(1)))
    func parsesHeaderNamesCaseInsensitively() throws {
        let parsed = try SCITTHeaders(httpHeaders: [
            "x-scitt-receipt": Base64.encode([1, 2, 3]),
            "x-ans-status-token": Base64.encode([4, 5, 6]),
        ])

        #expect(parsed.receipt == [1, 2, 3])
        #expect(parsed.statusToken == [4, 5, 6])
    }

    @Test(.timeLimit(.minutes(1)))
    func emptyHTTPHeadersProduceEmptyArtifacts() throws {
        let parsed = try SCITTHeaders(httpHeaders: [:])

        #expect(parsed.isEmpty)
        #expect(!parsed.hasReceipt)
        #expect(!parsed.hasStatusToken)
    }

    @Test(.timeLimit(.minutes(1)))
    func rejectsInvalidReceiptBase64() {
        #expect(throws: Base64.DecodingError.self) {
            try SCITTHeaders(httpHeaders: [
                SCITTHeaders.receiptHeaderName: "!!!",
            ])
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func rejectsInvalidStatusTokenBase64() {
        #expect(throws: Base64.DecodingError.self) {
            try SCITTHeaders(httpHeaders: [
                SCITTHeaders.statusTokenHeaderName: "!!!",
            ])
        }
    }
}
