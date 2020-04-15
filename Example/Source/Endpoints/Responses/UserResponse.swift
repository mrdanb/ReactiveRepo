import ReactiveRepo
import CoreData

struct UserResponse: Decodable {
    let identifier: String
    let name: String
    let age: Int
}

extension UserResponse: Serializing {
    func serialize(context: NSManagedObjectContext?) -> [User] {
        guard let context = context else { return [] }
        let user = User(context: context, response: self)
        return [user]
    }
}
