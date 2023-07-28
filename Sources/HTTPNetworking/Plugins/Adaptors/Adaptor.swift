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

// MARK: - AdaptationHandler

public typealias AdaptationHandler = (
    _ request: URLRequest,
    _ session: URLSession
) async throws -> URLRequest

// MARK: - Adaptor

/// An ``HTTPRequestAdaptor`` that can be used to manipulate a `URLRequest` before it is sent out over the network.
public struct Adaptor: HTTPRequestAdaptor {
    
    // MARK: Properties
    
    private let handler: AdaptationHandler
    
    // MARK: Initializers
    
    /// Creates an ``Adaptor`` from the provided handler.
    ///
    /// - Parameter handler: The handler to execute when the ``Adaptor`` is asked to adapt a `URLRequest`
    public init(_ handler: @escaping AdaptationHandler) {
        self.handler = handler
    }
    
    // MARK: HTTPRequestAdaptor
    
    public func adapt(_ request: URLRequest, for session: URLSession) async throws -> URLRequest {
        try await handler(request, session)
    }
}

// MARK: - HTTPRequest + Adaptor

extension HTTPRequest {
    /// Applies an ``Adaptor`` that handles request adaptation using the provided ``AdaptationHandler``.
    @discardableResult
    public func adapt(_ handler: @escaping AdaptationHandler) -> Self {
        adapt(with: Adaptor(handler))
    }
}
