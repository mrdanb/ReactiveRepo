import Foundation
import Combine

class RepositoryBoxBase<Entity>: Repository {
    func get(predicate: NSPredicate) -> AnyPublisher<[Entity], Error> {
        fatalError("Abstract method call")
    }

    func getAll() -> AnyPublisher<[Entity], Error> {
        fatalError("Abstract method call")
    }

    func delete(item: Entity) -> AnyPublisher<Entity, Error> {
        fatalError("Abstract method call")
    }

    func delete(predicate: NSPredicate) -> AnyPublisher<Int, Error> {
        fatalError("Abstract method call")
    }

    func deleteAll() -> AnyPublisher<Int, Error> {
        fatalError("Abstract method call")
    }

    func add(item: Entity) -> AnyPublisher<Entity, Error> {
        fatalError("Abstract method call")
    }

    func create(configure: (Entity) -> Void) -> AnyPublisher<Entity, Error> {
        fatalError("Abstract method call")
    }

    func sync<T>(task: @escaping (AnyRepository<Entity>) -> AnyPublisher<T, Error>) -> AnyPublisher<Changes<Entity>, Error> {
        fatalError("Abstract method call")
    }
}

final class RepositoryBox<RepositoryType: Repository>: RepositoryBoxBase<RepositoryType.Entity> {
    let base: RepositoryType

    init(base: RepositoryType) {
        self.base = base
    }

    override func get(predicate: NSPredicate) -> AnyPublisher<[RepositoryType.Entity], Error> {
        return base.get(predicate: predicate)
    }

    override func getAll() -> AnyPublisher<[RepositoryType.Entity], Error> {
        return base.getAll()
    }

    override func delete(item: Entity) -> AnyPublisher<Entity, Error> {
        return base.delete(item: item)
    }

    override func delete(predicate: NSPredicate) -> AnyPublisher<Int, Error> {
        return base.delete(predicate: predicate)
    }

    override func deleteAll() -> AnyPublisher<Int, Error> {
        return base.deleteAll()
    }

    override func add(item: Entity) -> AnyPublisher<Entity, Error> {
        return base.add(item: item)
    }

    override func create(configure: (Entity) -> Void) -> AnyPublisher<Entity, Error> {
        return base.create(configure: configure)
    }

    override func sync<T>(task: @escaping (AnyRepository<Entity>) -> AnyPublisher<T, Error>) -> AnyPublisher<Changes<Entity>, Error> {
        return base.sync(task: task)
    }
}

public struct AnyRepository<Entity>: Repository {

    let box: RepositoryBoxBase<Entity>

    public init<R>(_ repository: R) where R: Repository, R.Entity == Entity {
        if let erased = repository as? AnyRepository<Entity> {
            box = erased.box
        } else {
            box = RepositoryBox(base: repository)
        }
    }

    public func get(predicate: NSPredicate) -> AnyPublisher<[Entity], Error> {
        return box.get(predicate: predicate)
    }

    public func getAll() -> AnyPublisher<[Entity], Error> {
        return box.getAll()
    }

    public func delete(item: Entity) -> AnyPublisher<Entity, Error> {
        return box.delete(item: item)
    }

    public func delete(predicate: NSPredicate) -> AnyPublisher<Int, Error> {
        return box.delete(predicate: predicate)
    }

    public func deleteAll() -> AnyPublisher<Int, Error> {
        return box.deleteAll()
    }

    public func add(item: Entity) -> AnyPublisher<Entity, Error> {
        return box.add(item: item)
    }

    public func create(configure: (Entity) -> Void) -> AnyPublisher<Entity, Error> {
        return box.create(configure: configure)
    }

    public func sync<T>(task: @escaping (AnyRepository<Entity>) -> AnyPublisher<T, Error>) -> AnyPublisher<Changes<Entity>, Error> {
        return box.sync(task: task)
    }
}

public extension Repository {
    func eraseToAnyRepository() -> AnyRepository<Entity> {
        return AnyRepository(self)
    }
}
