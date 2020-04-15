import Foundation
import Combine
import CoreData

public class CoreDataRepository<Response, Entity>: Repository
    where
    Entity: NSManagedObject,
    Response: Decodable & Serializing,
    Response.Serialized == Entity,
    Response.Context == NSManagedObjectContext {

    private let persistentContainer: NSPersistentContainer
    private let source: Source
    private lazy var jsonDecoder = JSONDecoder()
    private lazy var syncQueue = DispatchQueue(label: "uk.co.dollop.croupier.syncqueue")
    private lazy var changes = Changes<Entity>()

    public init(persistentContainer: NSPersistentContainer, source: Source) {
        self.persistentContainer = persistentContainer
        self.source = source
        addObservers()
    }

    private func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleContextDidChange(_:)),
                                               name: .NSManagedObjectContextObjectsDidChange,
                                               object: persistentContainer.viewContext)
    }

    @objc private func handleContextDidChange(_ notification: Notification) {
        let updates = notification.objects(for: NSUpdatedObjectsKey, type: Entity.self).filter { $0.hasPersistentChangedValues }
        updates.forEach { changes.update($0) }

        let inserts = notification.objects(for: NSInsertedObjectsKey, type: Entity.self)
        inserts.forEach { changes.insert($0) }

        let deletes = notification.objects(for: NSDeletedObjectsKey, type: Entity.self).filter { $0.hasPersistentChangedValues }
        deletes.forEach { changes.delete($0) }
    }

    public func add(item: Entity) -> AnyPublisher<Entity, Error> {
        return persistentContainer.viewContext
            .insertObjectPublisher(item: item)
            .eraseToAnyPublisher()
    }

    public func get(predicate: NSPredicate?) -> AnyPublisher<[Entity], Error> {
        return persistentContainer.viewContext
            .fetchPublisher(of: Entity.self, predicate: predicate)
            .eraseToAnyPublisher()
    }

    public func delete(item: Entity) -> AnyPublisher<Entity, Error> {
        return persistentContainer.viewContext
            .deletePublisher(item: item)
            .eraseToAnyPublisher()
    }

    public func sync(from: String) -> AnyPublisher<Changes<Entity>, Error> {
        return source.data(for: from, parameters: nil)
            .receive(on: syncQueue)
            .decode(type: Response.self, decoder: jsonDecoder)
            .flatMap { response -> AnyPublisher<[NSManagedObjectID], Error> in
                self.persistentContainer.viewContext.createChildContext().performTask { (context, finished) in
                    context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                    let items = response.serialize(context:  context)
                    try context.save()
                    finished(items.map { $0.objectID })
                }.eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .tryMap { _ -> Changes<Entity> in
                self.changes.empty()
                try self.persistentContainer.viewContext.saveIfNeeded()
                return self.changes
            }
            .eraseToAnyPublisher()
    }

    private func items(for key: String, in notification: Notification) -> [Entity] {
        guard let userInfo = notification.userInfo else { return [] }
        guard let objects = userInfo[key] as? Set<NSManagedObject> else { return [] }
        return objects.compactMap { $0 as? Entity }
    }
}
