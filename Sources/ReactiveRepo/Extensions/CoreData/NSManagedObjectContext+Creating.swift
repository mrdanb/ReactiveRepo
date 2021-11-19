import Foundation
import CoreData
import Combine

extension NSManagedObjectContext {
    func createChildContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self
        return context
    }

    func childContextPublisher() -> AnyPublisher<NSManagedObjectContext, Never> {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self
        return Just(context)
            .eraseToAnyPublisher()
    }
}
