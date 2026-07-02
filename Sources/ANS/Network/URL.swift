import Foundation

extension URL {
    func ansAppendingPath(_ path: String) -> URL {
        var url = self
        for component in path.split(separator: "/").map(String.init) {
            url.appendPathComponent(component)
        }
        return url
    }

    func ansAppendingQuery(_ items: [URLQueryItem]) -> URL {
        guard !items.isEmpty, var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }
        components.queryItems = (components.queryItems ?? []) + items
        return components.url ?? self
    }
}
