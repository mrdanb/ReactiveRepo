import Foundation
import CoreData

extension NSManagedObject {
    static func createFetchRequest<T>(resultType: T.Type) -> NSFetchRequest<T> {
        return NSFetchRequest(entityName: entityName())
    }
}

extension NSManagedObject {
    static func entityName() -> String {
        return entity().name ?? String(describing: self)
    }
}
