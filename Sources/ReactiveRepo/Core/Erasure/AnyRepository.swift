import Foundation
import Combine

public struct AnyRepository<Response,Entity>: Repository {
    private let _get: (NSPredicate?) -> AnyPublisher<[Entity], Error>
    private let _sync: (String) -> AnyPublisher<Changes<Entity>, Error>
    private let _delete: (Entity) -> AnyPublisher<Entity, Error>
    private let _add: (Entity) -> AnyPublisher<Entity, Error>

    public init<R>(_ repository: R) where R: Repository, R.Entity == Entity, R.Response == Response {
        _get = repository.get
        _sync = repository.sync
        _delete = repository.delete
        _add = repository.add
    }

    public func get(predicate: NSPredicate? = nil) -> AnyPublisher<[Entity], Error> {
        return _get(predicate)
    }

    public func sync(from key: String) -> AnyPublisher<Changes<Entity>, Error> {
        return _sync(key)
    }

    public func delete(item: Entity) -> AnyPublisher<Entity, Error> {
        return _delete(item)
    }

    public func add(item: Entity) -> AnyPublisher<Entity, Error> {
        return _add(item)
    }
}

public extension Repository {
    func eraseToAnyRepository() -> AnyRepository<Response, Entity> {
        return AnyRepository(self)
    }
}
