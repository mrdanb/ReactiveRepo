import Foundation
import Combine

public protocol Source {
    func data(for key: String, parameters: [String: String]?) -> AnyPublisher<Data, Error>
}
