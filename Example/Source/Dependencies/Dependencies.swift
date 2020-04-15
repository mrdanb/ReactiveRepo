import Foundation
import CoreData

class Dependencies {
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ReactiveRepoExample")
        container.loadPersistentStores(completionHandler: { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    static var shared = Dependencies()
}
