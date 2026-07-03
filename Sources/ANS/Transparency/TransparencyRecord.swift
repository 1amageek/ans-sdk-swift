public struct TransparencyRecord: Sendable, Hashable {
    public let status: WireValue?
    public let schemaVersion: WireValue?
    public let fields: [String: JSONValue]

    public init(status: WireValue? = nil, schemaVersion: WireValue? = nil, fields: [String: JSONValue]) {
        self.status = status
        self.schemaVersion = schemaVersion
        self.fields = fields
    }
}

public struct TransparencyRecordAudit: Sendable, Hashable {
    public let records: [TransparencyRecord]
    public let pagination: Page?

    public init(records: [TransparencyRecord], pagination: Page? = nil) {
        self.records = records
        self.pagination = pagination
    }
}

#if !hasFeature(Embedded)
extension TransparencyRecord: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        var fields: [String: JSONValue] = [:]
        for key in container.allKeys {
            fields[key.stringValue] = try container.decode(JSONValue.self, forKey: key)
        }
        let status = try container.decodeIfPresent(WireValue.self, forKey: DynamicCodingKey("status"))
        let schemaVersion = try container.decodeIfPresent(WireValue.self, forKey: DynamicCodingKey("schemaVersion"))
        self.init(status: status, schemaVersion: schemaVersion, fields: fields)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        for (key, value) in fields {
            try container.encode(value, forKey: DynamicCodingKey(key))
        }
    }
}

extension TransparencyRecordAudit: Codable {}

private struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init(_ stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(stringValue: String) {
        self.init(stringValue)
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}
#endif
