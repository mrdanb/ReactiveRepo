import CoreData

@objc(User)
class User: NSManagedObject {
    @NSManaged var identifier: String
    @NSManaged var name: String
    @NSManaged var age: NSNumber

    func update(_ response: UserResponse) {
        identifier = response.identifier
        name = response.name
        age = NSNumber(value: response.age)
    }
}

extension User {
    convenience init(context: NSManagedObjectContext, response: UserResponse) {
        self.init(context: context)
        update(response)
    }
}
