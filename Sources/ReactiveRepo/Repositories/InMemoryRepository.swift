import Foundation
import Combine

public class InMemoryRepository<Response, Entity>: Repository
    where
    Entity: Equatable,
    Response: Serializing & Decodable,
    Response.Serialized == Entity {

    private let source: Source
    private lazy var decoder = JSONDecoder()
    private lazy var syncQueue = DispatchQueue(label: "uk.co.dollop.syncqueue")
    private lazy var store = [Entity]()
    
    public init(source: Source) {
        self.source = source
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
}

// MARK: - Syncing
public extension InMemoryRepository {
    func sync(from: String) -> AnyPublisher<Changes<Entity>, Error> {
        source.data(for: from, parameters: nil)
            .receive(on: syncQueue)
            .decode(type: Response.self, decoder: decoder)
            .map { response -> Changes<Entity> in
                let snapshot = self.store
                let newItems = response.serialize(context: nil).filter { !self.store.contains($0) }
                self.store.append(contentsOf: newItems)
                return Changes(self.store.difference(from: snapshot))
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
