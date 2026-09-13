import Foundation

nonisolated enum QuickLogLink {
    static let url: URL = {
        guard let url = URL(string: "trimtally://log") else {
            preconditionFailure("Invalid quick-log URL")
        }
        return url
    }()

    static func matches(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "trimtally"
            && url.host?.lowercased() == "log"
            && (url.path.isEmpty || url.path == "/")
            && url.user == nil && url.password == nil && url.port == nil
            && url.query == nil && url.fragment == nil
    }
}
