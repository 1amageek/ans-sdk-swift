import Foundation

public struct Audit: Sendable, Hashable, Codable {
    public struct Event: Sendable, Hashable, Codable {
        public let type: String
        public let agentID: Agent.ID?
        public let entryID: Entry.ID?
        public let payload: Data?
        public let proof: Proof?
        public let timestamp: Date?

        public init(type: String, agentID: Agent.ID? = nil, entryID: Entry.ID? = nil, payload: Data? = nil, proof: Proof? = nil, timestamp: Date? = nil) {
            self.type = type
            self.agentID = agentID
            self.entryID = entryID
            self.payload = payload
            self.proof = proof
            self.timestamp = timestamp
        }
    }

    public let events: [Event]
    public let nextCursor: String?

    public init(events: [Event], nextCursor: String? = nil) {
        self.events = events
        self.nextCursor = nextCursor
    }
}
