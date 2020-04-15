import Foundation
import CoreData
import Combine

public extension NSPersistentContainer {
    func performInBackground<T>(_ task: @escaping (_ context: NSManagedObjectContext, _ completion: @escaping (T) -> Void) throws -> Void) -> NSManagedObjectContext.PerformTaskPublisher<T> {
        let context = newBackgroundContext()
        return context.performTask(task)
    }
}
