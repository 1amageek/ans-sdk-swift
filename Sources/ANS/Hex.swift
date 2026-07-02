import Foundation

extension Data {
    var ansHexString: String {
        map { String(format: "%02x", $0) }.joined()
    }

    init(ansHexString: String) throws {
        guard ansHexString.count.isMultiple(of: 2) else {
            throw ParsingError("Hex string must contain an even number of characters")
        }

        var bytes: [UInt8] = []
        bytes.reserveCapacity(ansHexString.count / 2)

        var index = ansHexString.startIndex
        while index < ansHexString.endIndex {
            let next = ansHexString.index(index, offsetBy: 2)
            let byteString = String(ansHexString[index..<next])
            guard let byte = UInt8(byteString, radix: 16) else {
                throw ParsingError("Invalid hex byte: \(byteString)")
            }
            bytes.append(byte)
            index = next
        }

        self = Data(bytes)
    }
}
