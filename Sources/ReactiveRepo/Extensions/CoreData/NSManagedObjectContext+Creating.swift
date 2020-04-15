import Foundation
import CoreData

extension NSManagedObjectContext {
    func createChildContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self
        return context
    }
}
