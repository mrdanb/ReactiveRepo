import Foundation
import CoreData
import Combine

public extension NSManagedObjectContext {
    struct PerformTaskPublisher<T>: Publisher {
        public typealias Output = T
        public typealias Failure = Error

        public typealias Completion = (T) -> Void
        public typealias Task = (_ context: NSManagedObjectContext, _ completion: @escaping Completion) throws -> Void

        private let context: NSManagedObjectContext
        private let task: Task

        init(context: NSManagedObjectContext, _ task: @escaping Task) {
            self.context = context
            self.task = task
        }

        public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
            let subscription = Subscription(subscriber: subscriber, context: context, task: task)
            subscriber.receive(subscription: subscription)
        }
    }
}

fileprivate extension NSManagedObjectContext.PerformTaskPublisher {
    class Subscription<S>: Combine.Subscription
        where S: Subscriber,
        S.Input == Output,
        S.Failure == Failure {

        private var subscriber: S?
        private let context: NSManagedObjectContext
        private let task: Task

        init(subscriber: S, context: NSManagedObjectContext, task: @escaping Task) {
            self.subscriber = subscriber
            self.context = context
            self.task = task
        }

        func request(_ demand: Subscribers.Demand) {
            context.perform { [weak self] in
                do {
                    guard let self = self else { return }
                    try self.task(self.context) { result in
                        _ = self.subscriber?.receive(result)
                        self.subscriber?.receive(completion: .finished)
                        self.cancel()
                    }
                } catch {
                    self?.subscriber?.receive(completion: .failure(error))
                    self?.cancel()
                }
            }
        }

        func cancel() {
            subscriber = nil
        }
    }
}

public extension NSManagedObjectContext {
     func performTask<T>(_ task: @escaping (_ context: NSManagedObjectContext, _ completion: @escaping (T) -> Void) throws -> Void) -> PerformTaskPublisher<T> {
        return PerformTaskPublisher(context: self, task)
       }
}
