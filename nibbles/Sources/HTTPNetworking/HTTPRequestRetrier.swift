import Foundation

// MARK: - RetryStrategy

public enum RetryStrategy {
    /// Indicates that a failing request should not be retried.
    case concede
    /// Indicates that a failing request should be reattempted.
    case retry
}

// MARK: - RetryHandler

public typealias RetryHandler = (URLRequest, URLSession, Error) async -> RetryStrategy

// MARK: - HTTPRequestRetrier

public protocol HTTPRequestRetrier {
    func retry(_ request: URLRequest, for session: URLSession, dueTo error: Error) async -> RetryStrategy
}

// MARK: - HTTPRequestRetrier + Retriers

extension HTTPRequestRetrier where Self == Retrier {
    public static func retry(_ handler: @escaping RetryHandler) -> HTTPRequestRetrier {
        Retrier(handler)
    }
}
 
extension HTTPRequestRetrier where Self == ZipRetrier {
    public static func zip(retriers: [any HTTPRequestRetrier]) -> HTTPRequestRetrier {
        ZipRetrier(retriers)
    }
    
    public static func zip(retriers: any HTTPRequestRetrier...) -> HTTPRequestRetrier {
        ZipRetrier(retriers)
    }
}

// MARK: - Retrier

public struct Retrier: HTTPRequestRetrier {
    
    // MARK: Properties
    
    let handler: RetryHandler
    
    // MARK: Initializers
    
    public init(_ handler: @escaping RetryHandler) {
        self.handler = handler
    }
    
    // MARK: ResponseValidator
    
    public func retry(_ request: URLRequest, for session: URLSession, dueTo error: Error) async -> RetryStrategy {
        await handler(request, session, error)
    }
}

// MARK: - ZipRetrier

public struct ZipRetrier: HTTPRequestRetrier {
    
    // MARK: Properties
    
    let retriers: [any HTTPRequestRetrier]
    
    // MARK: Initializers
    
    public init(_ retriers: [any HTTPRequestRetrier]) {
        self.retriers = retriers
    }
    
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
