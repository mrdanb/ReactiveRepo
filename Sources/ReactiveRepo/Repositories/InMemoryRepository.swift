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

    public func get(predicate: NSPredicate?) -> AnyPublisher<[Entity], Error> {
        Just(store.filter { predicate?.evaluate(with: $0) ?? true })
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    public func sync(from: String) -> AnyPublisher<Changes<Entity>, Error> {
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

    public func delete(item: Entity) -> AnyPublisher<Entity, Error> {
        store.removeAll { $0 == item }
        return Just(item)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    public func add(item: Entity) -> AnyPublisher<Entity, Error> {
        store.append(item)
        return Just(item)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
