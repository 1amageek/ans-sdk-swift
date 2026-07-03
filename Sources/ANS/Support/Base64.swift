public enum Base64 {
    public enum DecodingError: Error, Sendable, Equatable {
        case invalidCharacter(UInt8)
        case invalidPadding
        case invalidLength
    }

    private static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".utf8)

    public static func encode(_ bytes: [UInt8]) -> String {
        guard !bytes.isEmpty else {
            return ""
        }

        var output: [UInt8] = []
        output.reserveCapacity(((bytes.count + 2) / 3) * 4)

        var index = 0
        while index < bytes.count {
            let remaining = bytes.count - index
            let first = bytes[index]
            let second = remaining > 1 ? bytes[index + 1] : 0
            let third = remaining > 2 ? bytes[index + 2] : 0

            output.append(alphabet[Int(first >> 2)])
            output.append(alphabet[Int(((first & 0x03) << 4) | (second >> 4))])
            output.append(remaining > 1 ? alphabet[Int(((second & 0x0f) << 2) | (third >> 6))] : 61)
            output.append(remaining > 2 ? alphabet[Int(third & 0x3f)] : 61)

            index += 3
        }

        return String(decoding: output, as: UTF8.self)
    }

    public static func decode(_ value: String) throws(DecodingError) -> [UInt8] {
        let input = Array(value.utf8).filter { byte in
            byte != 9 && byte != 10 && byte != 13 && byte != 32
        }

        guard !input.isEmpty else {
            return []
        }
        guard input.count % 4 == 0 else {
            throw .invalidLength
        }

        var output: [UInt8] = []
        output.reserveCapacity((input.count / 4) * 3)

        var index = 0
        var sawPadding = false
        while index < input.count {
            let chunk = Array(input[index..<index + 4])
            var values: [UInt8] = []
            values.reserveCapacity(4)

            for position in 0..<4 {
                let byte = chunk[position]
                if byte == 61 {
                    sawPadding = true
                    values.append(0)
                    continue
                }
                guard !sawPadding else {
                    throw .invalidPadding
                }
                values.append(try decodeSixBit(byte))
            }

            let first = (values[0] << 2) | (values[1] >> 4)
            output.append(first)

            if chunk[2] != 61 {
                let second = ((values[1] & 0x0f) << 4) | (values[2] >> 2)
                output.append(second)
            } else if chunk[3] != 61 {
                throw .invalidPadding
            }

            if chunk[3] != 61 {
                let third = ((values[2] & 0x03) << 6) | values[3]
                output.append(third)
            }

            index += 4
        }

        return output
    }

    private static func decodeSixBit(_ byte: UInt8) throws(DecodingError) -> UInt8 {
        switch byte {
        case 65...90:
            return byte - 65
        case 97...122:
            return byte - 97 + 26
        case 48...57:
            return byte - 48 + 52
        case 43:
            return 62
        case 47:
            return 63
        default:
            throw .invalidCharacter(byte)
        }
    }
}
