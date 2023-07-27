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
public enum RetryDecision {
    /// Indicates that a failing request should not be retried.
    case concede
    /// Indicates that a failing request should be reattempted.
    case retry
    /// Indicates that a failing request should be reattempted after provided delay.
    case retryAfterDelay(Duration)
}
