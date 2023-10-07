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

// MARK: - BuffableAsyncThrowingPublisher

/// A publisher that exposes its elements as a asynchronous throwing sequence with a specified buffering policy..
///
/// `BuffableAsyncThrowingPublisher` conforms to <doc://com.apple.documentation/documentation/Swift/AsyncSequence>, which allows callers to receive values with the `for`-`await`-`in` syntax, rather than attaching a ``Subscriber``.
///
/// Use the ``values(bufferingPolicy:)`` property of the ``Combine/Publisher`` protocol to wrap an existing publisher with an instance of this type.
public class BuffableAsyncThrowingPublisher<P>: AsyncSequence where P: Publisher {
    
    /// The type of element produced by this asynchronous sequence.
    public typealias Element = P.Output
    
    /// The iterator produced by this publisher.
    public typealias AsyncIterator = BuffableAsyncThrowingPublisher<P>

    // MARK: Properties
    
    private let stream: AsyncThrowingStream<Element, Error>
    
    private lazy var iterator = stream.makeAsyncIterator()
    
    private var cancellable: AnyCancellable?
    
    // MARK: Initializers
    
    /// Creates a publisher that exposes elements received from an upstream publisher as an asynchronous throwing sequence.
    ///
    /// - Parameter publisher: An upstream publisher. The asynchronous publisher converts elements received from this publisher into an asynchronous throwing sequence.
    public init(_ publisher: P, bufferingPolicy: AsyncThrowingStream<Element, Error>.Continuation.BufferingPolicy = .unbounded) {
        var subscription: AnyCancellable? = nil
        
        stream = AsyncThrowingStream(bufferingPolicy: bufferingPolicy) { continuation in
            subscription = publisher
                .handleEvents(receiveCancel: {
                    continuation.finish(throwing: nil)
                })
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        continuation.finish()
                    case .failure(let error):
                        continuation.finish(throwing: error)
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

// MARK: - BuffableAsyncThrowingPublisher + AsyncIteratorProtocol

extension BuffableAsyncThrowingPublisher: AsyncIteratorProtocol {
    public func next() async throws -> Element? {
        try await iterator.next()
    }
}

// MARK: - BuffableAsyncThrowingPublisher + Cancellable

extension BuffableAsyncThrowingPublisher: Cancellable {
    public func cancel() {
        cancellable?.cancel()
        cancellable = nil
    }
}

// MARK: - Publisher + BuffableAsyncThrowingPublisher

extension Publisher {
    /// The elements produced by the publisher, as an asynchronous throwing sequence.
    /// - Parameter bufferingPolicy: By providing a buffering policy, you can customize the behavior when sequence publishes values faster than they can be handled.
    /// 
    /// This property provides an ``BuffableAsyncThrowingPublisher``, which allows you to use the Swift `async`-`await` syntax to receive the publisher's elements. Because ``BuffableAsyncThrowingPublisher`` conforms to <doc://com.apple.documentation/documentation/Swift/AsyncSequence>, you iterate over its elements with a `for`-`await`-`in` loop, rather than attaching a subscriber.
    @_disfavoredOverload
    func values(bufferingPolicy: AsyncThrowingStream<Output, Error>.Continuation.BufferingPolicy) -> BuffableAsyncThrowingPublisher<Self> {
        BuffableAsyncThrowingPublisher(self, bufferingPolicy: bufferingPolicy)
    }
}
