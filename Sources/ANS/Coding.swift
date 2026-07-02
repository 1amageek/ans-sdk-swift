import Foundation

struct AnyCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

extension KeyedDecodingContainer where Key == AnyCodingKey {
    func decodeFirst<T: Decodable>(_ type: T.Type, for keys: [String]) throws -> T {
        for key in keys {
            let codingKey = AnyCodingKey(stringValue: key)
            if contains(codingKey) {
                return try decode(T.self, forKey: codingKey)
            }
        }
        throw DecodingError.keyNotFound(
            AnyCodingKey(stringValue: keys.first ?? ""),
            DecodingError.Context(codingPath: codingPath, debugDescription: "Missing any of keys: \(keys.joined(separator: ", "))")
        )
    }

    func decodeFirstIfPresent<T: Decodable>(_ type: T.Type, for keys: [String]) throws -> T? {
        for key in keys {
            let codingKey = AnyCodingKey(stringValue: key)
            if contains(codingKey) {
                return try decodeIfPresent(T.self, forKey: codingKey)
            }
        }
        return nil
    }
}
