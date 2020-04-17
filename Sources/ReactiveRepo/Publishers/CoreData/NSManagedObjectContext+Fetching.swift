import Foundation
import CoreData
import Combine

public extension NSManagedObjectContext {
    func fetchPublisher<T>(of type: T.Type, predicate: NSPredicate?) -> PerformTaskPublisher<[T]> where T: NSManagedObject {
        return PerformTaskPublisher(context: self) { context, finish in
            let request = T.createFetchRequest(resultType: T.self)
            request.predicate = predicate
            let items = try context.fetch(request)
            finish(items)
        }
    }
}
