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

    func batchDeletePublisher<T>(of type: T.Type, predicate: NSPredicate? = nil) -> PerformTaskPublisher<[NSManagedObjectID]> where T: NSManagedObject {
        return PerformTaskPublisher(context: self) { context, finish in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: T.entityName())
            fetchRequest.predicate = predicate

            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            deleteRequest.resultType = .resultTypeObjectIDs

            let deleteResult = try context.execute(deleteRequest) as? NSBatchDeleteResult
            let deleted = deleteResult?.result as? [NSManagedObjectID] ?? []

            try context.save()
            finish(deleted)
        }
    }
}
