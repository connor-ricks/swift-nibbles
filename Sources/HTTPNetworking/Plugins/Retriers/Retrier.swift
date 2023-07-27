import Foundation

public typealias RetryHandler = (
    _ request: URLRequest,
    _ session: URLSession,
    _ response: HTTPURLResponse?,
    _ error: Error,
    _ previousAttempts: Int
) async throws -> RetryStrategy

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
    ) async throws -> RetryStrategy {
        try await handler(request, session, response, error, previousAttempts)
    }
}

// MARK: - HTTPRequest + Retrier

extension HTTPRequest {
    /// Applies a ``Retrier`` that handles retry logic using the provided ``RetryHandler``.
    @discardableResult
    public func retry(_ handler: @escaping RetryHandler) -> Self {
        retry(with: Retrier(handler))
    }
}
