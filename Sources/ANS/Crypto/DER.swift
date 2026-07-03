enum DER {
    static func sequence(_ content: [UInt8]) -> [UInt8] {
        tagged(0x30, content)
    }

    static func set(_ content: [UInt8]) -> [UInt8] {
        tagged(0x31, content)
    }

    static func integer(_ value: Int) -> [UInt8] {
        if value == 0 {
            return tagged(0x02, [0])
        }

        var remaining = value
        var bytes: [UInt8] = []
        while remaining > 0 {
            bytes.insert(UInt8(remaining & 0xFF), at: 0)
            remaining >>= 8
        }
        if let first = bytes.first, first >= 0x80 {
            bytes.insert(0, at: 0)
        }
        return tagged(0x02, bytes)
    }

    static func objectIdentifier(_ value: String) throws(CryptoError) -> [UInt8] {
        let components = value.split(separator: ".")
        guard components.count >= 2,
              let first = Int(components[0]),
              let second = Int(components[1]),
              first >= 0,
              first <= 2,
              second >= 0,
              second <= 39 || first == 2 else {
            throw .invalidObjectIdentifier(value)
        }

        var body = [UInt8(first * 40 + second)]
        for component in components.dropFirst(2) {
            guard let number = Int(component), number >= 0 else {
                throw .invalidObjectIdentifier(value)
            }
            body.append(contentsOf: base128(number))
        }
        return tagged(0x06, body)
    }

    static func utf8String(_ value: String) -> [UInt8] {
        tagged(0x0C, Array(value.utf8))
    }

    static func octetString(_ bytes: [UInt8]) -> [UInt8] {
        tagged(0x04, bytes)
    }

    static func bitString(_ bytes: [UInt8]) -> [UInt8] {
        tagged(0x03, [0] + bytes)
    }

    static func taggedPrimitive(_ number: UInt8, content: [UInt8]) -> [UInt8] {
        tagged(0x80 | number, content)
    }

    static func taggedConstructed(_ number: UInt8, content: [UInt8]) -> [UInt8] {
        tagged(0xA0 | number, content)
    }

    static func tagged(_ tag: UInt8, _ content: [UInt8]) -> [UInt8] {
        [tag] + length(content.count) + content
    }

    private static func length(_ count: Int) -> [UInt8] {
        if count < 128 {
            return [UInt8(count)]
        }

        var remaining = count
        var bytes: [UInt8] = []
        while remaining > 0 {
            bytes.insert(UInt8(remaining & 0xFF), at: 0)
            remaining >>= 8
        }
        return [0x80 | UInt8(bytes.count)] + bytes
    }

    private static func base128(_ value: Int) -> [UInt8] {
        var remaining = value
        var bytes = [UInt8(remaining & 0x7F)]
        remaining >>= 7
        while remaining > 0 {
            bytes.insert(UInt8(remaining & 0x7F) | 0x80, at: 0)
            remaining >>= 7
        }
        return bytes
    }
}
