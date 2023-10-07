//
// MIT License
//
// Copyright (c) 2023 Connor Ricks
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Combine
import Foundation

// MARK: - BuffableAsyncPublisher

/// A publisher that exposes its elements as an asynchronous sequence with a specified buffering policy..
///
/// `BuffableAsyncPublisher` conforms to <doc://com.apple.documentation/documentation/Swift/AsyncSequence>, which allows callers to receive values with the `for`-`await`-`in` syntax, rather than attaching a ``Subscriber``.
///
/// Use the ``values(bufferingPolicy:)`` property of the ``Combine/Publisher`` protocol to wrap an existing publisher with an instance of this type.
public class BuffableAsyncPublisher<P> : AsyncSequence where P: Publisher, P.Failure == Never {
    
    /// The type of element produced by this asynchronous sequence.
    public typealias Element = P.Output
    
    /// The iterator produced by this publisher.
    public typealias AsyncIterator = BuffableAsyncPublisher<P>

    // MARK: Properties
    
    private let stream: AsyncStream<Element>
    
    private lazy var iterator = stream.makeAsyncIterator()
    
    private var cancellable: AnyCancellable?
    
    // MARK: Initializers
    
    /// Creates a publisher that exposes elements received from an upstream publisher as an asynchronous sequence.
    ///
    /// - Parameter publisher: An upstream publisher. The asynchronous publisher converts elements received from this publisher into an asynchronous sequence.
    public init(_ publisher: P, bufferingPolicy: AsyncStream<Element>.Continuation.BufferingPolicy = .unbounded) {
        var subscription: AnyCancellable? = nil
        stream = AsyncStream(bufferingPolicy: bufferingPolicy) { continuation in
            subscription = publisher
                .handleEvents(receiveCancel: {
                    continuation.finish()
                })
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        continuation.finish()
                    }
                }, receiveValue: { value in
                    continuation.yield(value)
                })
        }
        
        cancellable = subscription
    }

    // MARK: AsyncSequence
    
    public func makeAsyncIterator() -> Self { self }
}

// MARK: - BuffableAsyncPublisher + AsyncIteratorProtocol

extension BuffableAsyncPublisher: AsyncIteratorProtocol {
    public func next() async -> Element? {
        await iterator.next()
    }
}

// MARK: - BuffableAsyncPublisher + Cancellable

extension BuffableAsyncPublisher: Cancellable {
    public func cancel() {
        cancellable?.cancel()
        cancellable = nil
    }
}

// MARK: - Publisher + BuffableAsyncPublisher

extension Publisher where Failure == Never {
    /// The elements produced by the publisher, as an asynchronous sequence.
    /// - Parameter bufferingPolicy: By providing a buffering policy, you can customize the behavior when sequence publishes values faster than they can be handled.
    ///
    /// This property provides an ``BuffableAsyncPublisher``, which allows you to use the Swift `async`-`await` syntax to receive the publisher's elements. Because ``BuffableAsyncPublisher`` conforms to <doc://com.apple.documentation/documentation/Swift/AsyncSequence>, you iterate over its elements with a `for`-`await`-`in` loop, rather than attaching a subscriber.
    func values(bufferingPolicy: AsyncStream<Output>.Continuation.BufferingPolicy) -> BuffableAsyncPublisher<Self> {
        BuffableAsyncPublisher(self, bufferingPolicy: bufferingPolicy)
    }
}
