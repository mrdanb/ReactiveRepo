import Foundation
import Combine

public struct AnyRepository<Response,Entity>: Repository {
    private let _get: (NSPredicate) -> AnyPublisher<[Entity], Error>
    private let _getAll: () -> AnyPublisher<[Entity], Error>
    private let _sync: (String) -> AnyPublisher<Changes<Entity>, Error>
    private let _deleteWithEntity: (Entity) -> AnyPublisher<Entity, Error>
    private let _deleteWithPredicate: (NSPredicate) -> AnyPublisher<Int, Error>
    private let _deleteAll: () -> AnyPublisher<Int, Error>
    private let _add: (Entity) -> AnyPublisher<Entity, Error>

    public init<R>(_ repository: R) where R: Repository, R.Entity == Entity, R.Response == Response {
        _get = repository.get
        _getAll = repository.getAll
        _sync = repository.sync
        _deleteWithEntity = repository.delete
        _deleteWithPredicate = repository.delete
        _deleteAll = repository.deleteAll
        _add = repository.add
    }

    public func get(predicate: NSPredicate) -> AnyPublisher<[Entity], Error> {
        return _get(predicate)
    }

    public func getAll() -> AnyPublisher<[Entity], Error> {
        return _getAll()
    }

    public func sync(from key: String) -> AnyPublisher<Changes<Entity>, Error> {
        return _sync(key)
    }

    public func delete(item: Entity) -> AnyPublisher<Entity, Error> {
        return _deleteWithEntity(item)
    }

    public func delete(predicate: NSPredicate) -> AnyPublisher<Int, Error> {
        return _deleteWithPredicate(predicate)
    }

    public func deleteAll() -> AnyPublisher<Int, Error> {
        return _deleteAll()
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
