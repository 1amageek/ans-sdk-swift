public indirect enum JSONValue: Sendable, Hashable {
    case null
    case bool(Bool)
    case number(String)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])
}

#if !hasFeature(Embedded)
extension JSONValue: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
            return
        }
        do {
            let value = try container.decode(Bool.self)
            self = .bool(value)
            return
        } catch {
        }
        do {
            let value = try container.decode(Int.self)
            self = .number(String(value))
            return
        } catch {
        }
        do {
            let value = try container.decode(UInt.self)
            self = .number(String(value))
            return
        } catch {
        }
        do {
            let value = try container.decode(Double.self)
            self = .number(String(value))
            return
        } catch {
        }
        do {
            let value = try container.decode(String.self)
            self = .string(value)
            return
        } catch {
        }
        do {
            let value = try container.decode([JSONValue].self)
            self = .array(value)
            return
        } catch {
        }
        self = .object(try container.decode([String: JSONValue].self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .number(let value):
            if let int = Int(value) {
                try container.encode(int)
            } else if let double = Double(value) {
                try container.encode(double)
            } else {
                try container.encode(value)
            }
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }
}
#endif
