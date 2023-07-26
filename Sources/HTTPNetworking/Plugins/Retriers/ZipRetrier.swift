import Foundation

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
        dueTo error: Error,
        previousAttempts: Int
    ) async throws -> RetryStrategy {
        for retrier in retriers {
            try Task.checkCancellation()
            
            let strategy = try await retrier.retry(
                request,
                for: session,
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
