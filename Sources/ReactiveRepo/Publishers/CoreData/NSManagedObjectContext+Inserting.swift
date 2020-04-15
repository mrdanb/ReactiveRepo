import Foundation
import CoreData
import Combine

public extension NSManagedObjectContext {
    func insertObjectPublisher<T>(item: T) -> PerformTaskPublisher<T> where T: NSManagedObject {
        return PerformTaskPublisher(context: self) { context, finish in
            if item.managedObjectContext != context {
                context.insert(item)
            }
            try context.save()
            finish(item)
        }
    }
}
