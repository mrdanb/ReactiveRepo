import Foundation

enum Endpoints {
    case user
}

extension Endpoints {
    var path: String {
        switch self {
        case .user: return "5e9737f43000007300b6dcfa"
        }
    }
}
