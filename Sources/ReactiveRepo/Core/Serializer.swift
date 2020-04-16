import Foundation

public protocol Serializing {
    associatedtype Context
    associatedtype Serialized
    func serialize(context: Context?) -> [Serialized]
}

public extension Serializing {
    func serialize(context: Any?) -> [Self] {
        return [self]
    }
}
