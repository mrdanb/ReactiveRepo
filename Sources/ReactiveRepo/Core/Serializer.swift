import Foundation

public protocol Serializing {
    associatedtype Context
    associatedtype Serialized
    func serialize(context: Context?) -> [Serialized]
}
