import Foundation
import Combine

public class InMemoryRepository<Entity>: Repository where Entity: Equatable {
    public typealias Create = () -> Entity

    private lazy var decoder = JSONDecoder()
    private lazy var syncQueue = DispatchQueue(label: "uk.co.dollop.syncqueue")
    private lazy var store = [Entity]()
    private let creator: Create

    public init(creator: @escaping Create) {
        self.creator = creator
    }
}

// MARK: - Fetching
public extension InMemoryRepository {
    func get(predicate: NSPredicate) -> AnyPublisher<[Entity], Error> {
        Just(store.filter { predicate.evaluate(with: $0) })
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func getAll() -> AnyPublisher<[Entity], Error> {
        return Just(store)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

// MARK: - Deleting
public extension InMemoryRepository {
    func delete(item: Entity) -> AnyPublisher<Entity, Error> {
        store.removeAll { $0 == item }
        return Just(item)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func delete(predicate: NSPredicate) -> AnyPublisher<Int, Error> {
        get(predicate: predicate)
            .handleEvents(receiveOutput: { [unowned self] toDelete in
                self.store.removeAll(where: { toDelete.contains($0) })
            })
            .map { $0.count }
            .eraseToAnyPublisher()
    }

    func deleteAll() -> AnyPublisher<Int, Error> {
        let deleted = store.count
        store.removeAll()
        return Just(deleted)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

// MARK: - Adding
public extension InMemoryRepository {
    func add(item: Entity) -> AnyPublisher<Entity, Error> {
        store.append(item)
        return Just(item)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func create(configure: (Entity) -> Void) -> AnyPublisher<Entity, Error> {
        let new = creator()
        configure(new)
        store.append(new)
        return Just(new)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

// MARK: - Syncing
public extension InMemoryRepository {
    func sync(task: (AnyRepository<Entity>) -> Void) -> AnyPublisher<Changes<Entity>, Error> {
        let snapshot = store
        task(eraseToAnyRepository())
        let changes = Changes(store.difference(from: snapshot))
        return Just(changes)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func sync<T>(task: @escaping (AnyRepository<Entity>) -> AnyPublisher<T, Error>) -> AnyPublisher<Changes<Entity>, Error> {
        let snapshot = store
        return task(eraseToAnyRepository())
            .subscribe(on: syncQueue)
            .map { (_: T) -> Changes<Entity> in
                return Changes(self.store.difference(from: snapshot))
            }
            .eraseToAnyPublisher()
    }
}
