import Foundation
import CoreData
import Combine
public extension NSManagedObjectContext {
    func deletePublisher<T>(item: T) -> PerformTaskPublisher<T> where T: NSManagedObject {
        return PerformTaskPublisher(context: self) { context, finish in
            context.delete(item)
            try context.save()
            finish(item)
        }
    }
}
