enum Hex {
    static func encode<Bytes: Sequence>(_ bytes: Bytes) -> String where Bytes.Element == UInt8 {
        let table = Array("0123456789abcdef".utf8)
        var encoded: [UInt8] = []
        encoded.reserveCapacity(bytes.underestimatedCount * 2)

        for byte in bytes {
            encoded.append(table[Int(byte >> 4)])
            encoded.append(table[Int(byte & 0x0F)])
        }

        return String(decoding: encoded, as: UTF8.self)
    }

    static func decode(_ string: String) throws(ParsingError) -> [UInt8] {
        let scalars = Array(string.utf8)
        guard scalars.count.isMultiple(of: 2) else {
            throw ParsingError.invalidFingerprint(string)
        }

        var bytes: [UInt8] = []
        bytes.reserveCapacity(scalars.count / 2)

        var index = 0
        while index < scalars.count {
            guard let high = nibble(scalars[index]), let low = nibble(scalars[index + 1]) else {
                throw ParsingError.invalidFingerprint(string)
            }
            bytes.append((high << 4) | low)
            index += 2
        }

        return bytes
    }

    private static func nibble(_ byte: UInt8) -> UInt8? {
        switch byte {
        case 48...57:
            return byte - 48
        case 65...70:
            return byte - 55
        case 97...102:
            return byte - 87
        default:
            return nil
        }
    }
}
