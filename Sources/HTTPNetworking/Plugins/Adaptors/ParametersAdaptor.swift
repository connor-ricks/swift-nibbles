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

// MARK: - ParametersAdaptor

/// An ``HTTPRequestAdaptor`` that can be used to append query parameters to a request before it is sent out over the network.
///
/// > Warning: This adaptor will **not** overwrite existing parameters, instead it will append to existing parameters.
public struct ParametersAdaptor: HTTPRequestAdaptor {
    
    // MARK: Properties
    
    /// The query parameters to append to an incoming request.
    public let items: [URLQueryItem]
    
    // MARK: Initializers
    
    /// Creates a ``ParametersAdaptor`` from the provided query parameters.
    ///
    /// - Parameter items: The query parameters to append to an incoming request.
    public init(items: [URLQueryItem]) {
        self.items = items
    }
    
    // MARK: HTTPRequestAdaptor
    
    public func adapt(_ request: URLRequest, for session: URLSession) async throws -> URLRequest {
        var request = request
        guard let url = request.url else {
            preconditionFailure("URLRequest should contain a valid URL at this point.")
        }
        
        request.url = url.appending(queryItems: items)
        return request
    }
}

// MARK: - HTTPRequest + ParametersAdaptor

extension HTTPRequest {
    /// Applies a ``ParametersAdaptor`` that appends the provided query parameters to the request.
    @discardableResult
    public func adapt(queryItems: [URLQueryItem]) -> Self {
        adapt(with: ParametersAdaptor(items: queryItems))
    }
}
