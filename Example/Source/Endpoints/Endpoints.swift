import Foundation

enum Endpoints {
    case user
    case scores
}

extension Endpoints {
    var path: String {
        switch self {
        case .user: return "/5e9737f43000007300b6dcfa"
        case .scores: return "/5e98285b3500004e00c47f19"
        }
    }
}
