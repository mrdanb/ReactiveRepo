import Foundation

public class Changes<Entity> {

    public private(set) var deleted: [Entity]
    public private(set) var inserted: [Entity]
    public private(set) var updated: [Entity]

    public init(deleted: [Entity] = [],
                inserted: [Entity] = [],
                updated: [Entity] = []) {
        self.deleted = deleted
        self.inserted = inserted
        self.updated = updated
    }

    public func delete(_ entity: Entity) {
        deleted.append(entity)
    }

    public func insert(_ entity: Entity) {
        inserted.append(entity)
    }

    public func update(_ entity: Entity) {
        updated.append(entity)
    }

    public func empty() {
        deleted.removeAll()
        inserted.removeAll()
        updated.removeAll()
    }

    public func changes(for type: ChangeType) -> [Entity] {
        switch type {
        case .deleted: return deleted
        case.inserted: return inserted
        case .updated: return updated
        }
    }
}

public extension Changes {

    convenience init(_ diff: CollectionDifference<Entity>) {
        var inserts = [Entity]()
        var deletes = [Entity]()
        for change in diff {
            switch change {
            case .insert(_, let element, _):
                inserts.append(element)
            case .remove(_, let element, _):
                deletes.append(element)
            }
        }
        self.init(deleted: deletes, inserted: inserts)
    }
}

public extension Changes {
    enum ChangeType {
        case inserted
        case deleted
        case updated
    }
}

extension Changes: CustomDebugStringConvertible {
    public var debugDescription: String {
        let description =  """
        Changes(
            Updated: \(updated.count)
            Inserted: \(inserted.count)
            Deleted: \(deleted.count)
        )
        """
        return description
    }
}
