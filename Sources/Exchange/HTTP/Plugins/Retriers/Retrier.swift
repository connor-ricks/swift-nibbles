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

// MARK: - RetryHandler

public typealias RetryHandler = (
    _ request: URLRequest,
    _ session: URLSession,
    _ response: HTTPURLResponse?,
    _ error: Error,
    _ previousAttempts: Int
) async throws -> RetryDecision

// MARK: - Retrier

/// An ``HTTPRequestRetrier`` that can be used to retry an ``HTTPRequest`` upon failure.
public struct Retrier: HTTPRequestRetrier {
    
    // MARK: Properties
    
    private let handler: RetryHandler
    
    // MARK: Initializers
    
    
    /// Creates a ``Retrier`` from the provided handler.
    ///
    /// - Parameter handler: The handler to execute when the ``Retrier`` is asked if it should retry.
    public init(_ handler: @escaping RetryHandler) {
        self.handler = handler
    }
    
    // MARK: ResponseValidator
    
    public func retry(
        _ request: URLRequest,
        for session: URLSession,
        with response: HTTPURLResponse?,
        dueTo error: Error,
        previousAttempts: Int
    ) async throws -> RetryDecision {
        try await handler(request, session, response, error, previousAttempts)
    }
}

// MARK: - HTTPRequest + Retrier

extension HTTPRequest {
    /// Applies a ``Retrier`` that handles retry logic using the provided ``RetryHandler``.
    public func retry(_ handler: @escaping RetryHandler) -> Self {
        retry(with: Retrier(handler))
    }
}
