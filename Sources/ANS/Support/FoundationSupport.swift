#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

#if canImport(FoundationEssentials) || canImport(Foundation)
#if !hasFeature(Embedded)
public enum JSON {
    public static func decode<Value: Decodable>(_ type: Value.Type, from bytes: [UInt8]) throws(any Error) -> Value {
        try JSONDecoder().decode(type, from: Data(bytes))
    }

    public static func encode<Value: Encodable>(_ value: Value) throws(any Error) -> [UInt8] {
        Array(try JSONEncoder().encode(value))
    }
}
#endif

public extension Fingerprint {
    static func sha256(der: Data) throws(ParsingError) -> Fingerprint {
        try sha256(bytes: der)
    }
}

public extension Request {
    init(method: Method, uri: URI, headers: [String: String] = [:], body: Data) {
        self.init(method: method, uri: uri, headers: headers, body: Array(body))
    }
}

public extension Response {
    var data: Data {
        Data(body)
    }
}
#endif
