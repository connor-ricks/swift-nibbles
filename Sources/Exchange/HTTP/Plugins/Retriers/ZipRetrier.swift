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

// MARK: - ZipRetrier

/// An ``HTTPRequestRetrier`` that combines multiple retriers into one, executing each retrier in sequence.
public struct ZipRetrier: HTTPRequestRetrier {
    
    // MARK: Properties
    
    /// An array of retriers that make up this retrier.
    public let retriers: [any HTTPRequestRetrier]
    
    // MARK: Initializers
        
    /// Creates a ``ZipRetrier`` from the provided retriers.
    ///
    /// - Parameter retriers: The retriers that should be executed in sequence
    public init(_ retriers: [any HTTPRequestRetrier]) {
        self.retriers = retriers
    }
    
    /// Creates a ``ZipRetrier`` from the provided retriers.
    ///
    /// - Parameter retriers: The retriers that should be executed in sequence
    public init(_ retriers: any HTTPRequestRetrier...) {
        self.retriers = retriers
    }
    
    // MARK: ResponseValidator
    
    public func retry(
        _ request: URLRequest,
        for session: URLSession,
        with response: HTTPURLResponse?,
        dueTo error: Error,
        previousAttempts: Int
    ) async throws -> RetryDecision {
        for retrier in retriers {
            try Task.checkCancellation()
            
            let strategy = try await retrier.retry(
                request,
                for: session,
                with: response,
                dueTo: error,
                previousAttempts: previousAttempts
            )
            
            switch strategy {
            case .concede:
                continue
            case .retry, .retryAfterDelay:
                return strategy
            }
        }
        
        return .concede
    }
}

// MARK: - HTTPRequest + ZipRetrier

extension HTTPRequest {
    /// Applies a ``ZipRetrier`` that bundles up all the provided retriers.
    public func retry(zipping retriers: [any HTTPRequestRetrier]) -> Self {
        retry(with: ZipRetrier(retriers))
    }
}
