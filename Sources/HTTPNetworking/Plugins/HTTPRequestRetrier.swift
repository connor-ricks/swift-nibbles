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

// MARK: - HTTPRequestRetrier

/// An ``HTTPRequestRetrier`` is used to retry an ``HTTPRequest`` that fails
///
/// By conforming to ``HTTPRequestRetrier`` you can implement both simple and complex logic for retrying an ``HTTPRequest`` when
/// it fails. Common uses cases include retrying a given amount of times due to a specific error such as poor network connectivity.
public protocol HTTPRequestRetrier {
    func retry(
        _ request: URLRequest,
        for session: URLSession,
        with response: HTTPURLResponse?,
        dueTo error: Error,
        previousAttempts: Int
    ) async throws -> RetryDecision
}

// MARK: - RetryDecision

/// A strategy that indicates to an ``HTTPRequest`` what approach should be taken when
/// attempting to retry upon failure.
public enum RetryDecision: Equatable {
    /// Indicates that a failing request should not be retried.
    case concede
    /// Indicates that a failing request should be reattempted.
    case retry
    /// Indicates that a failing request should be reattempted after provided delay.
    case retryAfterDelay(Duration)
}
