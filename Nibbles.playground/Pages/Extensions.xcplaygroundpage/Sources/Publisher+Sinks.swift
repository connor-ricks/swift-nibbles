import Foundation
import Combine

// MARK: - DisposableBag

/// A thread safe bag of `AnyCancellables`
public class DisposableBag {
    private let lock = NSLock()
    private var cancellables = Set<AnyCancellable>()
    
    public var count: Int {
        return cancellables.count
    }

    public func store(_ anyCancellable: AnyCancellable) {
        lock.lock()
        cancellables.insert(anyCancellable)
        lock.unlock()
    }

    public func dispose(_ anyCancellable: AnyCancellable) {
        lock.lock()
        cancellables.remove(anyCancellable)
        lock.unlock()
    }
    
    public func empty() {
        lock.lock()
        cancellables.removeAll()
        lock.unlock()
    }
}

// MARK: - Standard Sinks

extension Publisher {
    /// Attaches a subscriber with closure-based behavior
    ///
    /// - Parameters:
    ///   - receiveValue: The closure to execute on receipt of a value.
    ///   - receiveError: The closure to execute on completion due to an error.
    ///   - receiveCompletion: The closure to execute on normal completion.
    /// - Returns: A cancellable instance, which you use when you end assignment of the received value. Deallocation of the result will tear down the subscription stream.
    public func sink(
        receiveValue: @escaping (Output) -> Void,
        receiveError: @escaping (Failure) -> Void,
        receiveCompletion: (() -> Void)? = nil
    ) -> AnyCancellable {
        let subscriber = Subscribers.Sink<Output, Failure>(
            receiveValue: receiveValue,
            receiveError: receiveError,
            receiveCompletion: receiveCompletion
        )

        subscribe(subscriber)
        return AnyCancellable(subscriber)
    }
}

extension Publisher where Failure == Never {
    /// Attaches a subscriber, that will never fail, with closure-based behavior
    ///
    /// - Parameters:
    ///   - receiveValue: The closure to execute on receipt of a value.
    ///   - receiveCompletion: The closure to execute on normal completion.
    /// - Returns: A cancellable instance, which you use when you end assignment of the received value. Deallocation of the result will tear down the subscription stream.
    public func sink(
        receiveValue: @escaping (Output) -> Void,
        receiveCompletion: (() -> Void)? = nil
    ) -> AnyCancellable {
        sink(
            receiveValue: receiveValue,
            receiveError: { never in },
            receiveCompletion: receiveCompletion
        )
    }
}

// MARK: - DisposableBag Sinks

extension Publisher {
    /// Attaches a subscriber with closure-based behavior that will store and cleanup after itself.
    ///
    /// By providing a `DisposableBag`, this sink will automatically store and cleanup after itself when the publishers completes either normally or by failure.
    /// This prevents large sets of finished subscriptions from building up, as each subscription is removed from the `DisposableBag` upon completion.
    ///
    /// - Parameters:
    ///   - receiveValue: The closure to execute on receipt of a value.
    ///   - receiveError: The closure to execute on completion due to an error.
    ///   - receiveCompletion: The closure to execute on normal completion.
    ///   - bag: The `DisposableBag` that should store this subscriber.
    /// - Returns: A cancellable instance, which you use when you end assignment of the received value. Deallocation of the result will tear down the subscription stream.
    @discardableResult
    public func sink(
        receiveValue: @escaping (Output) -> Void,
        receiveError: @escaping (Failure) -> Void,
        receiveCompletion: (() -> Void)? = nil,
        bag: DisposableBag
    ) -> AnyCancellable {
        var retainedCancellable: AnyCancellable?

        let cleanupBlock = {
            guard let retainedCancellable else { return }
            bag.dispose(retainedCancellable)
        }

        let publisher = handleEvents(receiveCancel: {
            cleanupBlock()
        })

        let subscriber = Subscribers.Sink<Output, Failure>(
            receiveValue: receiveValue,
            receiveError: { error in
                receiveError(error)
                cleanupBlock()
            },
            receiveCompletion: {
                receiveCompletion?()
                cleanupBlock()
            }
        )

        let cancellable = AnyCancellable(subscriber)
        bag.store(cancellable)
        retainedCancellable = cancellable

        publisher.subscribe(subscriber)
        return cancellable
    }
}

extension Publisher where Failure == Never {
    /// Attaches a subscriber, that will never fail, with closure-based behavior that will store and cleanup after itself.
    ///
    /// By providing a `DisposableBag`, this sink will automatically store and cleanup after itself when the publishers completes.
    /// This prevents large sets of complete subscriptions from building up, as each subscription is removed from the `DisposableBag` upon completion.
    ///
    /// - Parameters:
    ///   - receiveValue: The closure to execute on receipt of a value.
    ///   - receiveCompletion: The closure to execute on normal completion.
    ///   - bag: The `DisposableBag` that should store this subscriber.
    /// - Returns: A cancellable instance, which you use when you end assignment of the received value. Deallocation of the result will tear down the subscription stream.
    @discardableResult
    public func sink(
        receiveValue: @escaping (Output) -> Void,
        receiveCompletion: (() -> Void)? = nil,
        bag: DisposableBag
    ) -> AnyCancellable {
        sink(
            receiveValue: receiveValue,
            receiveError: { never in },
            receiveCompletion: receiveCompletion,
            bag: bag
        )
    }
}

// MARK: - Convenience Sink Subscriber

private extension Subscribers.Sink {
    convenience init(
        receiveValue: @escaping (Input) -> Void,
        receiveError: @escaping (Failure) -> Void,
        receiveCompletion: (() -> Void)? = nil
    ) {
        self.init(
            receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    receiveError(error)
                case.finished:
                    receiveCompletion?()
                }
            },
            receiveValue: receiveValue
        )
    }
}
