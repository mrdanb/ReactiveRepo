import Foundation
import Combine

public protocol Repository: Fetching, Syncing, Deleting, Adding {
    associatedtype Entity
    associatedtype Response
}

public protocol Fetching {
    associatedtype Entity
    func get(predicate: NSPredicate) -> AnyPublisher<[Entity], Error>
    func getAll() -> AnyPublisher<[Entity], Error>
}

public protocol Syncing {
    associatedtype Entity
    func sync(from: String) -> AnyPublisher<Changes<Entity>, Error>
}

public protocol Deleting {
    associatedtype Entity
    func delete(item: Entity) -> AnyPublisher<Entity, Error>
    func delete(predicate: NSPredicate) -> AnyPublisher<Int, Error>
    func deleteAll() -> AnyPublisher<Int, Error>
}

public protocol Adding {
    associatedtype Entity
    func add(item: Entity) -> AnyPublisher<Entity, Error>
}
