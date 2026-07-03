public struct Endpoint: Sendable, Hashable {
    public struct ProtocolKind: Sendable, Hashable, RawRepresentable, CustomStringConvertible {
        public let rawValue: String

        public var description: String {
            rawValue
        }

        public init(rawValue: String) {
            self.rawValue = Self.canonical(rawValue)
        }

        public static let a2a = Self(rawValue: "A2A")
        public static let mcp = Self(rawValue: "MCP")
        public static let httpAPI = Self(rawValue: "HTTP-API")
        public static let payment = Self(rawValue: "PAYMENT")

        private static func canonical(_ value: String) -> String {
            switch value.uppercased() {
            case "HTTP_API":
                return "HTTP-API"
            default:
                return value.uppercased()
            }
        }
    }

    public struct TransportKind: Sendable, Hashable, RawRepresentable, CustomStringConvertible {
        public let rawValue: String

        public var description: String {
            rawValue
        }

        public init(rawValue: String) {
            self.rawValue = Self.canonical(rawValue)
        }

        public static let streamableHTTP = Self(rawValue: "STREAMABLE-HTTP")
        public static let sse = Self(rawValue: "SSE")
        public static let jsonRPC = Self(rawValue: "JSON-RPC")
        public static let grpc = Self(rawValue: "GRPC")
        public static let rest = Self(rawValue: "REST")
        public static let http = Self(rawValue: "HTTP")

        private static func canonical(_ value: String) -> String {
            switch value.uppercased() {
            case "STREAMABLE_HTTP":
                return "STREAMABLE-HTTP"
            case "JSON_RPC":
                return "JSON-RPC"
            default:
                return value.uppercased()
            }
        }
    }

    public let url: URI
    public let protocolKind: ProtocolKind
    public let transports: [TransportKind]
    public let metadataURL: URI?
    public let metadataHash: String?
    public let documentationURL: URI?
    public let functions: [Function]

    public init(
        url: URI,
        protocolKind: ProtocolKind,
        transports: [TransportKind],
        metadataURL: URI? = nil,
        metadataHash: String? = nil,
        documentationURL: URI? = nil,
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

#if !hasFeature(Embedded)
extension Endpoint.ProtocolKind: Codable {}
extension Endpoint.TransportKind: Codable {}
extension Endpoint: Codable {}
#endif
