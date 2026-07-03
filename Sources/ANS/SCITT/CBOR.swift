enum CBOR {
    enum Error: Swift.Error, Sendable, Equatable {
        case truncated
        case unsupportedIndefiniteLength
        case invalidAdditionalInfo(UInt8)
        case invalidUTF8
        case invalidType
        case nestingLimitExceeded
        case collectionLimitExceeded
        case integerOverflow
    }

    enum Key: Sendable, Hashable {
        case int(Int64)
        case text(String)
    }

    indirect enum Value: Sendable, Hashable {
        case unsigned(UInt64)
        case negative(Int64)
        case bytes([UInt8])
        case text(String)
        case array([Item])
        case map([Key: Item])
        case tag(UInt64, Item)
        case simple(UInt8)

        var intValue: Int64? {
            switch self {
            case .unsigned(let value):
                guard value <= UInt64(Int64.max) else {
                    return nil
                }
                return Int64(value)
            case .negative(let value):
                return value
            default:
                return nil
            }
        }

        var bytesValue: [UInt8]? {
            if case .bytes(let bytes) = self {
                return bytes
            }
            return nil
        }

        var textValue: String? {
            if case .text(let text) = self {
                return text
            }
            return nil
        }
    }

    struct Item: Sendable, Hashable {
        let value: Value
        let raw: [UInt8]
    }

    static func decode(_ bytes: [UInt8]) throws(Error) -> Item {
        var decoder = Decoder(bytes: bytes)
        let item = try decoder.decodeItem(depth: 0)
        guard decoder.isAtEnd else {
            throw .invalidType
        }
        return item
    }

    static func encodeSigStructure(protectedBytes: [UInt8], payload: [UInt8]) -> [UInt8] {
        var output: [UInt8] = []
        encodeArrayHeader(count: 4, into: &output)
        encodeText("Signature1", into: &output)
        encodeBytes(protectedBytes, into: &output)
        encodeBytes([], into: &output)
        encodeBytes(payload, into: &output)
        return output
    }
}

private struct Decoder {
    private static let maximumDepth = 16
    private static let maximumArrayElements = 1024
    private static let maximumMapPairs = 256

    private let bytes: [UInt8]
    private var offset: Int = 0

    init(bytes: [UInt8]) {
        self.bytes = bytes
    }

    var isAtEnd: Bool {
        offset == bytes.count
    }

    mutating func decodeItem(depth: Int) throws(CBOR.Error) -> CBOR.Item {
        guard depth <= Self.maximumDepth else {
            throw .nestingLimitExceeded
        }
        let start = offset
        let initial = try readByte()
        let major = initial >> 5
        let additional = initial & 0x1f

        let value: CBOR.Value
        switch major {
        case 0:
            value = .unsigned(try readArgument(additional))
        case 1:
            let argument = try readArgument(additional)
            guard argument <= UInt64(Int64.max) else {
                throw .integerOverflow
            }
            value = .negative(-1 - Int64(argument))
        case 2:
            value = .bytes(try readBytes(length: readLength(additional)))
        case 3:
            let textBytes = try readBytes(length: readLength(additional))
            let text = String(decoding: textBytes, as: UTF8.self)
            value = .text(text)
        case 4:
            let count = try readLength(additional)
            guard count <= Self.maximumArrayElements else {
                throw .collectionLimitExceeded
            }
            var values: [CBOR.Item] = []
            values.reserveCapacity(count)
            for _ in 0..<count {
                values.append(try decodeItem(depth: depth + 1))
            }
            value = .array(values)
        case 5:
            let count = try readLength(additional)
            guard count <= Self.maximumMapPairs else {
                throw .collectionLimitExceeded
            }
            var values: [CBOR.Key: CBOR.Item] = [:]
            values.reserveCapacity(count)
            for _ in 0..<count {
                let keyItem = try decodeItem(depth: depth + 1)
                let key = try mapKey(from: keyItem)
                let item = try decodeItem(depth: depth + 1)
                values[key] = item
            }
            value = .map(values)
        case 6:
            let tag = try readArgument(additional)
            let item = try decodeItem(depth: depth + 1)
            value = .tag(tag, item)
        case 7:
            value = .simple(additional)
        default:
            throw .invalidType
        }

        return CBOR.Item(value: value, raw: Array(bytes[start..<offset]))
    }

    private mutating func readByte() throws(CBOR.Error) -> UInt8 {
        guard offset < bytes.count else {
            throw .truncated
        }
        let byte = bytes[offset]
        offset += 1
        return byte
    }

    private mutating func readArgument(_ additional: UInt8) throws(CBOR.Error) -> UInt64 {
        switch additional {
        case 0...23:
            return UInt64(additional)
        case 24:
            return UInt64(try readByte())
        case 25:
            return UInt64(try readBigEndian(count: 2))
        case 26:
            return UInt64(try readBigEndian(count: 4))
        case 27:
            return try readBigEndian(count: 8)
        case 31:
            throw .unsupportedIndefiniteLength
        default:
            throw .invalidAdditionalInfo(additional)
        }
    }

    private mutating func readLength(_ additional: UInt8) throws(CBOR.Error) -> Int {
        let argument = try readArgument(additional)
        guard argument <= UInt64(Int.max) else {
            throw .integerOverflow
        }
        return Int(argument)
    }

    private mutating func readBigEndian(count: Int) throws(CBOR.Error) -> UInt64 {
        guard offset + count <= bytes.count else {
            throw .truncated
        }
        var value: UInt64 = 0
        for _ in 0..<count {
            value = (value << 8) | UInt64(bytes[offset])
            offset += 1
        }
        return value
    }

    private mutating func readBytes(length: Int) throws(CBOR.Error) -> [UInt8] {
        guard offset + length <= bytes.count else {
            throw .truncated
        }
        let result = Array(bytes[offset..<offset + length])
        offset += length
        return result
    }

    private func mapKey(from item: CBOR.Item) throws(CBOR.Error) -> CBOR.Key {
        switch item.value {
        case .unsigned(let value):
            guard value <= UInt64(Int64.max) else {
                throw .integerOverflow
            }
            return .int(Int64(value))
        case .negative(let value):
            return .int(value)
        case .text(let value):
            return .text(value)
        default:
            throw .invalidType
        }
    }
}

extension CBOR {
    static func encodeArrayHeader(count: Int, into output: inout [UInt8]) {
        encodeHeader(major: 4, argument: UInt64(count), into: &output)
    }

    static func encodeText(_ text: String, into output: inout [UInt8]) {
        let bytes = Array(text.utf8)
        encodeHeader(major: 3, argument: UInt64(bytes.count), into: &output)
        output.append(contentsOf: bytes)
    }

    static func encodeBytes(_ bytes: [UInt8], into output: inout [UInt8]) {
        encodeHeader(major: 2, argument: UInt64(bytes.count), into: &output)
        output.append(contentsOf: bytes)
    }

    private static func encodeHeader(major: UInt8, argument: UInt64, into output: inout [UInt8]) {
        let prefix = major << 5
        switch argument {
        case 0..<24:
            output.append(prefix | UInt8(argument))
        case 24...UInt64(UInt8.max):
            output.append(prefix | 24)
            output.append(UInt8(argument))
        case 256...UInt64(UInt16.max):
            output.append(prefix | 25)
            output.append(UInt8((argument >> 8) & 0xff))
            output.append(UInt8(argument & 0xff))
        case 65_536...UInt64(UInt32.max):
            output.append(prefix | 26)
            for shift in stride(from: 24, through: 0, by: -8) {
                output.append(UInt8((argument >> UInt64(shift)) & 0xff))
            }
        default:
            output.append(prefix | 27)
            for shift in stride(from: 56, through: 0, by: -8) {
                output.append(UInt8((argument >> UInt64(shift)) & 0xff))
            }
        }
    }
}
