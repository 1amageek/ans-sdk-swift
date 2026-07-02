import Foundation

public struct Function: Sendable, Hashable, Codable, Identifiable {
    public let id: String
    public let name: String
    public let tags: [String]

    public init(id: String, name: String, tags: [String] = []) {
        self.id = id
        self.name = name
        self.tags = tags
    }
}

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
}
