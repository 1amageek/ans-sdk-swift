import Foundation

public struct Endpoint: Sendable, Hashable, Codable {
    public struct ProtocolKind: CanonicalWireValue, ExpressibleByStringLiteral {
        public let rawValue: String

        public init(_ rawValue: String) {
            switch rawValue {
            case "HTTP_API":
                self.rawValue = "HTTP-API"
            default:
                self.rawValue = rawValue
            }
        }

        public init(stringLiteral value: String) {
            self.init(value)
        }

        public static let a2a = Self("A2A")
        public static let mcp = Self("MCP")
        public static let httpAPI = Self("HTTP-API")
        public static let payment = Self("PAYMENT")
    }

    public struct TransportKind: CanonicalWireValue, ExpressibleByStringLiteral {
        public let rawValue: String

        public init(_ rawValue: String) {
            switch rawValue {
            case "STREAMABLE_HTTP":
                self.rawValue = "STREAMABLE-HTTP"
            case "JSON_RPC":
                self.rawValue = "JSON-RPC"
            default:
                self.rawValue = rawValue
            }
        }

        public init(stringLiteral value: String) {
            self.init(value)
        }

        public static let streamableHTTP = Self("STREAMABLE-HTTP")
        public static let sse = Self("SSE")
        public static let jsonRPC = Self("JSON-RPC")
        public static let grpc = Self("GRPC")
        public static let rest = Self("REST")
        public static let http = Self("HTTP")
    }

    public let url: URL
    public let protocolKind: ProtocolKind
    public let transports: [TransportKind]
    public let metadataURL: URL?
    public let metadataHash: String?
    public let documentationURL: URL?
    public let functions: [Function]

    public init(
        url: URL,
        protocolKind: ProtocolKind,
        transports: [TransportKind] = [],
        metadataURL: URL? = nil,
        metadataHash: String? = nil,
        documentationURL: URL? = nil,
        functions: [Function] = []
    ) {
        self.url = url
        self.protocolKind = protocolKind
        self.transports = transports
        self.metadataURL = metadataURL
        self.metadataHash = metadataHash
        self.documentationURL = documentationURL
        self.functions = functions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        self.url = try container.decodeFirst(URL.self, for: ["agentUrl", "url"])
        self.protocolKind = try container.decodeFirst(ProtocolKind.self, for: ["protocol", "protocolKind"])
        self.transports = try container.decodeFirstIfPresent([TransportKind].self, for: ["transports"]) ?? []
        self.metadataURL = try container.decodeFirstIfPresent(URL.self, for: ["metaDataUrl", "metadataUrl", "metadataURL"])
        self.metadataHash = try container.decodeFirstIfPresent(String.self, for: ["metaDataHash", "metadataHash"])
        self.documentationURL = try container.decodeFirstIfPresent(URL.self, for: ["documentationUrl", "documentationURL"])
        self.functions = try container.decodeFirstIfPresent([Function].self, for: ["functions"]) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyCodingKey.self)
        try container.encode(url, forKey: AnyCodingKey(stringValue: "agentUrl"))
        try container.encode(protocolKind, forKey: AnyCodingKey(stringValue: "protocol"))
        try container.encode(transports, forKey: AnyCodingKey(stringValue: "transports"))
        try container.encodeIfPresent(metadataURL, forKey: AnyCodingKey(stringValue: "metaDataUrl"))
        try container.encodeIfPresent(metadataHash, forKey: AnyCodingKey(stringValue: "metaDataHash"))
        try container.encodeIfPresent(documentationURL, forKey: AnyCodingKey(stringValue: "documentationUrl"))
        try container.encode(functions, forKey: AnyCodingKey(stringValue: "functions"))
    }
}
