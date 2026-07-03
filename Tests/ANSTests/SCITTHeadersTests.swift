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
}
