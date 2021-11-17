import Foundation
import Combine
import CoreData

public class CoreDataRepository<Entity>: Repository where Entity: NSManagedObject {

    private let context: NSManagedObjectContext
    private lazy var jsonDecoder = JSONDecoder()
    private lazy var syncQueue = DispatchQueue(label: "uk.co.danbennett.reactiverepo.syncqueue")
    private lazy var changes = Changes<Entity>()

    public convenience init(persistentContainer: NSPersistentContainer) {
        self.init(context: persistentContainer.viewContext)
    }

    public init(context: NSManagedObjectContext) {
        self.context = context
        addObservers()
    }

    private func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleContextDidChange(_:)),
                                               name: .NSManagedObjectContextObjectsDidChange,
                                               object: context)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleContextDidSave(_:)),
                                               name: .NSManagedObjectContextDidSave,
                                               object: context)
    }

    @objc private func handleContextDidChange(_ notification: Notification) {
        let updates = notification.objects(for: NSUpdatedObjectsKey, type: Entity.self)
            .filter { $0.hasPersistentChangedValues && !changes.updated.contains($0) }
        updates.forEach { changes.update($0) }
    }

    @objc private func handleContextDidSave(_ notification: Notification) {
        let inserts = notification.objects(for: NSInsertedObjectsKey, type: Entity.self)
        inserts.forEach { changes.insert($0) }

    let deletes = notification.objects(for: NSDeletedObjectsKey, type: Entity.self)
        deletes.forEach { changes.delete($0) }
    }

    private func items(for key: String, in notification: Notification) -> [Entity] {
        guard let userInfo = notification.userInfo else { return [] }
        guard let objects = userInfo[key] as? Set<NSManagedObject> else { return [] }
        return objects.compactMap { $0 as? Entity }
    }
}

// MARK: - Fetching
public extension CoreDataRepository {
    func get(predicate: NSPredicate) -> AnyPublisher<[Entity], Error> {
        return context
            .fetchPublisher(of: Entity.self, predicate: predicate)
            .eraseToAnyPublisher()
    }

    func getAll() -> AnyPublisher<[Entity], Error> {
        return context
            .fetchPublisher(of: Entity.self)
            .eraseToAnyPublisher()
    }
}

// MARK: - Deleting
public extension CoreDataRepository {
    func delete(item: Entity) -> AnyPublisher<Entity, Error> {
        return context
            .deletePublisher(item: item)
            .eraseToAnyPublisher()
    }

    func delete(predicate: NSPredicate) -> AnyPublisher<Int, Error> {
        return context
            .batchDeletePublisher(of: Entity.self, predicate: predicate)
            .map { $0.count }
            .eraseToAnyPublisher()
    }

    func deleteAll() -> AnyPublisher<Int, Error> {
        return context
            .batchDeletePublisher(of: Entity.self)
            .map { $0.count }
            .eraseToAnyPublisher()
    }
}

// MARK: - Adding
public extension CoreDataRepository {
    func add(item: Entity) -> AnyPublisher<Entity, Error> {
        return context
            .insertObjectPublisher(item: item)
            .eraseToAnyPublisher()
    }
}

// MARK: - Syncing
public extension CoreDataRepository {
    func sync(task: @escaping (AnyRepository<Entity>) -> Void) -> AnyPublisher<Changes<Entity>, Error> {
        return context.createChildContext().performTask { context, completion in
            context.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
            task(CoreDataRepository(context: context).eraseToAnyRepository())
//            try self.context.save() // do we need this?
            completion(self.changes)
        }
        .eraseToAnyPublisher()
    }
}
