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

import Foundation

// MARK: - HeadersAdaptor

/// An ``HTTPRequestAdaptor`` that can be used to append HTTP headers to a request before it is sent out over the network.
public struct HeadersAdaptor: HTTPRequestAdaptor {

    // MARK: CustomCollisionStrategyHandler
    
    public typealias CustomCollisionStrategyHandler = (_ field: String, _ oldValue: String, _ newValue: String) -> String
    
    // MARK: CollisionStrategy
    
    /// A strategy used to handle occurences of header field collisions between the existing request headers and the new being added.
    public enum CollisionStrategy {
        /// A strategy where collisions result in the older value taking precedence.
        case useOlderValue
        /// A strategy where collisions result in the newer value taking precedence.
        case useNewerValue
        /// A strategy where collisions result in the newer value being appended to the older value using a comma as the delimiter
        case useBothValues
        /// A strategy where the handler receives the field and both the old and new values. The value returned by the handler will be used as the field's value.
        case custom(CustomCollisionStrategyHandler)
    }
    
    // MARK: Properties
    
    /// The HTTP headers to be appended to an incoming request.
    public let headers: [String: String]
    
    /// The strategy to use when the adaptor encounters a field collision.
    public let strategy: CollisionStrategy

    // MARK: Initializers
    
    /// Creates a ``HeadersAdaptor`` from the provided HTTP headers.
    /// 
    /// - Parameters:
    ///   - headers: The HTTP headers to be appended to an incoming request.
    ///   - strategy: The strategy to use when the adaptor encounters a field collision.
    public init(headers: [String: String], strategy: CollisionStrategy) {
        self.headers = headers
        self.strategy = strategy
    }

    // MARK: HTTPRequestAdaptor
    
    public func adapt(_ request: URLRequest, for session: URLSession) async throws -> URLRequest {
        var request = request
        for (key, newValue) in headers {
            if let oldValue = request.value(forHTTPHeaderField: key) {
                switch strategy {
                case .useOlderValue:
                    continue
                case .useNewerValue:
                    request.setValue(newValue, forHTTPHeaderField: key)
                case .useBothValues:
                    request.addValue(newValue, forHTTPHeaderField: key)
                case .custom(let handler):
                    request.setValue(handler(key, oldValue, newValue), forHTTPHeaderField: key)
                }
            } else {
                request.setValue(newValue, forHTTPHeaderField: key)
            }
        }

        return request
    }
}

// MARK: - HTTPRequest + HeadersAdaptor

extension HTTPRequest {
    /// Applies a ``HeadersAdaptor`` that appends the provided headers to the request.
    @discardableResult
    public func adapt(headers: [String: String], strategy: HeadersAdaptor.CollisionStrategy = .useNewerValue) -> Self {
        adapt(with: HeadersAdaptor(headers: headers, strategy:  strategy))
    }
}
