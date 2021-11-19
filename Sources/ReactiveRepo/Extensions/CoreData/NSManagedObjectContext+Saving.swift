import Foundation
import CoreData
import Combine

extension NSManagedObjectContext {
    func saveIfNeeded() throws {
        guard hasChanges else { return }
        try save()
    }

    func saveIfNeededPublisher() -> AnyPublisher<Bool, Error> {
        guard hasChanges else {
            return Just(false)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        }

        do {
            try save()
            return Just(true)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }
}
