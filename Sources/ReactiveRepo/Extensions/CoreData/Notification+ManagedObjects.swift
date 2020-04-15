import Foundation
import CoreData

extension Notification {
    func objects<T: NSManagedObject>(for key: String, type: T.Type) -> [T] {
        guard let userInfo = userInfo else { return [] }
        guard let objects = userInfo[key] as? Set<NSManagedObject> else { return [] }
        return objects.compactMap { $0 as? T }
    }
}
