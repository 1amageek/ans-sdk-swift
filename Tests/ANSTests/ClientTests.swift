import Testing
import ANS

@Suite("Client")
struct ClientTests {
    @Test(.timeLimit(.minutes(1)))
    func authorizedJSONHeadersUseConfiguredAuthorization() throws {
        let baseURI = try URI(rawValue: "https://registry.ans.godaddy.com")
        let bearer = Client(
            configuration: Configuration(registryBaseURI: baseURI, authorization: .bearer("token")),
            transport: ClientRecordingTransport(response: Response(statusCode: 200, body: []))
        )
        let jwt = Client(
            configuration: Configuration(registryBaseURI: baseURI, authorization: .jwt("jwt-token")),
            transport: ClientRecordingTransport(response: Response(statusCode: 200, body: []))
        )
        let apiKey = Client(
            configuration: Configuration(registryBaseURI: baseURI, authorization: .apiKey(id: "id", secret: "secret")),
            transport: ClientRecordingTransport(response: Response(statusCode: 200, body: []))
        )

        #expect(bearer.authorizedJSONHeaders()["Authorization"] == "Bearer token")
        #expect(jwt.authorizedJSONHeaders()["Authorization"] == "sso-jwt jwt-token")
        #expect(apiKey.authorizedJSONHeaders()["Authorization"] == "sso-key id:secret")
        #expect(bearer.authorizedJSONHeaders()["Accept"] == "application/json")
        #expect(bearer.authorizedJSONHeaders()["Content-Type"] == "application/json")
    }

    @Test(.timeLimit(.minutes(1)))
    func getAddsQueryAndAuthorizationHeaders() async throws {
        let transport = ClientRecordingTransport(response: Response(statusCode: 200, body: Array(#"{"value":"ok"}"#.utf8)))
        let client = Client(
            configuration: Configuration(
                registryBaseURI: try URI(rawValue: "https://registry.ans.godaddy.com/v2"),
                authorization: .bearer("token")
            ),
            transport: transport
        )

        let payload = try await client.get(ClientPayload.self, path: "/ans/agents", queryItems: [
            ("limit", "20"),
            ("cursor", "a b"),
            ("skip", nil),
        ])
        let request = await transport.lastRequest()

        #expect(payload == ClientPayload(value: "ok"))
        #expect(request?.method == .get)
        #expect(request?.uri.rawValue == "https://registry.ans.godaddy.com/v2/ans/agents?limit=20&cursor=a%20b")
        #expect(request?.headers["Authorization"] == "Bearer token")
        #expect(request?.headers["Accept"] == "application/json")
    }

    @Test(.timeLimit(.minutes(1)))
    func postEncodesBodyAndThrowsHTTPError() async throws {
        let transport = ClientRecordingTransport(response: Response(statusCode: 409, body: Array("conflict".utf8)))
        let client = Client(
            configuration: Configuration(registryBaseURI: try URI(rawValue: "https://registry.ans.godaddy.com")),
            transport: transport
        )

        do {
            _ = try await client.post(ClientPayload.self, path: "/ans/agents", body: ClientPayload(value: "created"))
            #expect(Bool(false))
        } catch let error as HTTPError {
            let request = await transport.lastRequest()
            let body = String(decoding: request?.body ?? [], as: UTF8.self)

            #expect(error.statusCode == 409)
            #expect(error.body == Array("conflict".utf8))
            #expect(request?.method == .post)
            #expect(body.contains("\"value\":\"created\""))
        } catch {
            #expect(Bool(false))
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func transparencyLogRequestsRequireConfiguredBaseURI() async throws {
        let client = Client(
            configuration: Configuration(registryBaseURI: try URI(rawValue: "https://registry.ans.godaddy.com")),
            transport: ClientRecordingTransport(response: Response(statusCode: 200, body: []))
        )

        do {
            _ = try await client.getFromTransparencyLog(ClientPayload.self, path: "/checkpoint")
            #expect(Bool(false))
        } catch let error as ValidationError {
            #expect(error == .missingTransparencyLogBaseURI)
        } catch {
            #expect(Bool(false))
        }
    }
}

private struct ClientPayload: Codable, Equatable, Sendable {
    let value: String
}

private actor ClientRecordingTransport: Transport {
    private let response: Response
    private var request: Request?

    init(response: Response) {
        self.response = response
    }

    func send(_ request: Request) async throws(any Error) -> Response {
        self.request = request
        return response
    }

    func lastRequest() -> Request? {
        request
    }
}
