enum PEM {
    static func encode(type: String, der: [UInt8]) -> String {
        let encoded = Base64.encode(der)
        var lines: [String] = []
        var index = encoded.startIndex
        while index < encoded.endIndex {
            let end = encoded.index(index, offsetBy: 64, limitedBy: encoded.endIndex) ?? encoded.endIndex
            lines.append(String(encoded[index..<end]))
            index = end
        }
        return "-----BEGIN \(type)-----\n\(lines.joined(separator: "\n"))\n-----END \(type)-----"
    }
}
