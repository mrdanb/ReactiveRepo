import Foundation
import Combine

public class InMemoryRepository<Entity>: Repository where Entity: Equatable {
    private lazy var decoder = JSONDecoder()
    private lazy var syncQueue = DispatchQueue(label: "uk.co.dollop.syncqueue")
    private lazy var store = [Entity]()
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
}
