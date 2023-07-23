import Foundation

// MARK: - RetryStrategy

/// A strategy that indicates to an ``HTTPRequest`` what approach should be taken when
/// attempting to retry upon failure.
public enum RetryStrategy {
    /// Indicates that a failing request should not be retried.
    case concede
    /// Indicates that a failing request should be reattempted.
    case retry
}

// MARK: - RetryHandler

public typealias RetryHandler = (URLRequest, URLSession, Error) async -> RetryStrategy

// MARK: - HTTPRequestRetrier

/// An ``HTTPRequestRetrier`` is used to retry an ``HTTPRequest`` that fails
///
/// By conforming to ``HTTPRequestRetrier`` you can implement both simple and complex logic for retrying an ``HTTPRequest`` when
/// it fails. Common uses cases include retrying a given amount of times due to a specific error such as poor network connectivity.
public protocol HTTPRequestRetrier {
    func retry(_ request: URLRequest, for session: URLSession, dueTo error: Error) async -> RetryStrategy
}

// MARK: - HTTPRequestRetrier + Retriers

extension HTTPRequestRetrier where Self == Retrier {
    /// Craetes a ``Retrier`` from the provided ``RetryHandler``.
    public static func retry(_ handler: @escaping RetryHandler) -> Retrier {
        Retrier(handler)
    }
}
 
extension HTTPRequestRetrier where Self == ZipRetrier {
    /// Creates a ``Retrier`` from the provided array of ``HTTPRequestRetrier`` values.
    public static func zip(retriers: [any HTTPRequestRetrier]) -> ZipRetrier {
        ZipRetrier(retriers)
    }
    
    /// Creates a ``Retrier`` from the provided variadic list of ``HTTPRequestRetrier`` values.
    public static func zip(retriers: any HTTPRequestRetrier...) -> ZipRetrier {
        ZipRetrier(retriers)
    }
}

// MARK: - Retrier

/// An ``HTTPRequestRetrier`` that can be used to retry an ``HTTPRequest`` upon failure.
public struct Retrier: HTTPRequestRetrier {
    
    // MARK: Properties
    
    let handler: RetryHandler
    
    // MARK: Initializers
    
    
    /// Creates a ``Retrier`` from the provided handler.
    ///
    /// - Parameter handler: The handler to execute when the ``Retrier`` is asked if it should retry.
    public init(_ handler: @escaping RetryHandler) {
        self.handler = handler
    }
    
    // MARK: ResponseValidator
    
    public func retry(_ request: URLRequest, for session: URLSession, dueTo error: Error) async -> RetryStrategy {
        await handler(request, session, error)
    }
}

// MARK: - ZipRetrier

/// An ``HTTPRequestRetrier`` that combines multiple retriers into one, executing each retrier in sequence.
public struct ZipRetrier: HTTPRequestRetrier {
    
    // MARK: Properties
    
    let retriers: [any HTTPRequestRetrier]
    
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
    
    public func retry(_ request: URLRequest, for session: URLSession, dueTo error: Error) async -> RetryStrategy {
        for retrier in retriers {
            let strategy = await retrier.retry(request, for: session, dueTo: error)
            if case .concede = strategy {
                continue
            } else {
                return strategy
            }
        }
        
        return .concede
    }
}
