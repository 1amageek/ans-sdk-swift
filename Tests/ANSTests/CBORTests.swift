import Testing
@testable import ANS

@Suite("CBOR")
struct CBORTests {
    @Test(.timeLimit(.minutes(1)))
    func rejectsInvalidUTF8TextString() throws {
        do {
            _ = try CBOR.decode([0x61, 0x80])
            #expect(Bool(false))
        } catch let error as CBOR.Error {
            #expect(error == .invalidUTF8)
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func decodesValidUTF8TextString() throws {
        let item = try CBOR.decode([0x62, 0x6f, 0x6b])

        #expect(item.value.textValue == "ok")
    }
}
