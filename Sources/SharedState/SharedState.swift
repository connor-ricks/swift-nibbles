//
// MIT License
//
// Copyright (c) 2024 Connor Ricks
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
import ConcurrencyExtras
import Foundation
import Fuse

public typealias SharedStateUpdateBlock<T> = (_ old: T, _ new: T) async -> Void


/// A simple container that encapsulates an object allowing others to subscribe to and monitor changes to the state.
/// 
/// Frequently use in PointFree's TCA architecture to subscribe long-running effects to shared state changes.
///
/// ```
/// let settings = SharedState(Settings(theme: .dark), onChange: { old, new in
///     datastore.saveTheme(new)
/// })
///
/// for await theme in settings {
///     update(for settings)
/// }
/// 
/// for await theme in settings[stream: \.theme] {
///     update(for theme)
/// }
/// ```
@dynamicMemberLookup
public struct SharedState<T: Equatable & Sendable>: @unchecked Sendable {
    
    // MARK: Properties
    
    private let state: LockIsolated<T>
    private let subject = PassthroughSubject<T, Never>()
    private let onChange: SharedStateUpdateBlock<T>?
    
    // MARK: Initializers
    
    public init(_ value: T, onChange: SharedStateUpdateBlock<T>? = nil) {
        self.state = LockIsolated(value)
        self.onChange = onChange
    }
    
    // MARK: Stream
    
    public subscript<Value>(dynamicMember keyPath: KeyPath<T, Value>) -> Value {
        self()[keyPath: keyPath]
    }
    
    public subscript<Value: Equatable>(
        stream keyPath: KeyPath<T, Value>,
        bufferingPolicy: AsyncStream<Value>.Continuation.BufferingPolicy = .unbounded
    ) -> AsyncStream<Value> {
        
        return subject
            .map(keyPath)
            .filter { state.value[keyPath: keyPath] != $0 }
            .values(bufferingPolicy: bufferingPolicy)
            .eraseToStream()
    }
    
    // MARK: Publisher
    
    public subscript<Value: Equatable>(
        publisher keyPath: KeyPath<T, Value>
    ) -> AnyPublisher<Value, Never> {
        return subject
            .map(keyPath)
            .filter { state.value[keyPath: keyPath] != $0 }
            .eraseToAnyPublisher()
    }
    
    public var publisher: AnyPublisher<T, Never> {
        subject.eraseToAnyPublisher()
    }
    
    // MARK: Methods
    
    public func callAsFunction() -> T {
        state.value
    }
    
    private func set(_ newValue: T) async {
        let oldValue = state.value
        state.withValue {
            $0 = newValue
            subject.send(newValue)
        }
        await onChange?(oldValue, newValue)
    }
    
    public func stream(bufferingPolicy: AsyncStream<T>.Continuation.BufferingPolicy = .unbounded) -> AsyncStream<T> {
        subject
            .filter { state.value != $0 }
            .values(bufferingPolicy: bufferingPolicy).eraseToStream()
    }
    
    public func mutate(_ operation: (inout T) async throws -> Void) async rethrows {
        var value = self()
        try await operation(&value)
        await set(value)
        // Yielding in order to allow subscribers time to react before proceeding onwards.
        await Task.yield()
    }
}
