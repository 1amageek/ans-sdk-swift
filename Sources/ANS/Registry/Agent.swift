import Foundation

public struct Agent: Sendable, Hashable, Codable, Identifiable {
    public struct ID: Sendable, Hashable, Codable, CustomStringConvertible {
        public let rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        public var description: String { rawValue }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            self.init(try container.decode(String.self))
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
    }

    public let id: ID
    public let entryID: Entry.ID?
    public let name: Name?
    public let host: Host
    public let displayName: String
    public let description: String?
    public let version: Version?
    public let status: Registration.Status
    public let endpoints: [Endpoint]

    public init(
        id: ID,
        entryID: Entry.ID? = nil,
        name: Name? = nil,
        host: Host,
        displayName: String,
        description: String? = nil,
        version: Version? = nil,
        status: Registration.Status,
        endpoints: [Endpoint] = []
    ) {
        self.id = id
        self.entryID = entryID
        self.name = name
        self.host = host
        self.displayName = displayName
        self.description = description
        self.version = version
        self.status = status
        self.endpoints = endpoints
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        self.id = try container.decodeFirst(ID.self, for: ["agentId", "id"])
        self.entryID = try container.decodeFirstIfPresent(Entry.ID.self, for: ["ansId", "entryId", "entryID"])
        self.name = try container.decodeFirstIfPresent(Name.self, for: ["ansName", "name"])
        self.host = try container.decodeFirst(Host.self, for: ["agentHost", "host"])
        self.displayName = try container.decodeFirst(String.self, for: ["agentDisplayName", "displayName"])
        self.description = try container.decodeFirstIfPresent(String.self, for: ["agentDescription", "description"])
        self.version = try container.decodeFirstIfPresent(Version.self, for: ["version"])
        self.status = try container.decodeFirst(Registration.Status.self, for: ["agentStatus", "status"])
        self.endpoints = try container.decodeFirstIfPresent([Endpoint].self, for: ["endpoints"]) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyCodingKey.self)
        try container.encode(id, forKey: AnyCodingKey(stringValue: "agentId"))
        try container.encodeIfPresent(entryID, forKey: AnyCodingKey(stringValue: "ansId"))
        try container.encodeIfPresent(name, forKey: AnyCodingKey(stringValue: "ansName"))
        try container.encode(host, forKey: AnyCodingKey(stringValue: "agentHost"))
        try container.encode(displayName, forKey: AnyCodingKey(stringValue: "agentDisplayName"))
        try container.encodeIfPresent(description, forKey: AnyCodingKey(stringValue: "agentDescription"))
        try container.encodeIfPresent(version, forKey: AnyCodingKey(stringValue: "version"))
        try container.encode(status, forKey: AnyCodingKey(stringValue: "agentStatus"))
        try container.encode(endpoints, forKey: AnyCodingKey(stringValue: "endpoints"))
    }
}
