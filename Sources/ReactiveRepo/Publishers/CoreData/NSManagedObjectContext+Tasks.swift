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
            let subscription = PerformTask(subscriber: subscriber, context: context, task: task)
            subscriber.receive(subscription: subscription)
        }
    }
}

private extension NSManagedObjectContext.PerformTaskPublisher {
    class PerformTask<S>: Combine.Subscription
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
    struct PerformTaskMapPublisher<T>: Publisher {
        public typealias Output = T
        public typealias Failure = Error

        public typealias Task = (_ context: NSManagedObjectContext) throws -> AnyPublisher<T, Failure>

        private let context: NSManagedObjectContext
        private let task: Task

        init(context: NSManagedObjectContext, _ task: @escaping Task) {
            self.context = context
            self.task = task
        }

        public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
            let subscription = PerformTaskMap(subscriber: subscriber, context: context, task: task)
            subscriber.receive(subscription: subscription)
        }
    }
}

private extension NSManagedObjectContext.PerformTaskMapPublisher {
    class PerformTaskMap<S>: Combine.Subscription
        where S: Subscriber,
        S.Input == Output,
        S.Failure == Failure {

        private var subscriber: S?
        private var cancellable: AnyCancellable?
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

                    let child = try self.task(self.context)

                    self.cancellable = child
                        .sink { result in
                            self.subscriber?.receive(completion: result)
                            self.cancel()
                        } receiveValue: { output in
                            _ = self.subscriber?.receive(output)
                        }

                } catch {
                    self?.subscriber?.receive(completion: .failure(error))
                    self?.cancel()
                }
            }
        }

        func cancel() {
            subscriber = nil
            cancellable?.cancel()
            cancellable = nil
        }
    }
}


public extension NSManagedObjectContext {
     func performTask<T>(_ task: @escaping (_ context: NSManagedObjectContext, _ completion: @escaping (T) -> Void) throws -> Void) -> PerformTaskPublisher<T> {
        return PerformTaskPublisher(context: self, task)
       }

    func performTaskMap<T>(_ task: @escaping (_ context: NSManagedObjectContext) throws -> AnyPublisher<T, Error>) -> PerformTaskMapPublisher<T> {
       return PerformTaskMapPublisher(context: self, task)
      }
}
