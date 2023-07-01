import Foundation

/// An object that requests data.
public struct HTTPRequestor {
    
    // MARK: Properties
    
    public let data: (URLRequest) async throws -> (Data, HTTPURLResponse)
    
    // MARK: Initializers
    
    public init(data: @escaping (URLRequest) async throws -> (Data, HTTPURLResponse)) {
        self.data = data
    }
}

public extension HTTPRequestor {
    /// A live implementation of an ``HTTPRequestor`` that will utilize the provided session to perform requests.
    /// 
    /// - Parameter session: The session that should power networking requests.
    /// - Returns: An ``HTTPRequestor``
    static func live(session: URLSession = .shared) -> HTTPRequestor {
        HTTPRequestor { request in
            let (data, response) = try await session.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                throw URLError(.cannotParseResponse)
            }
            
            return (data, response)
        }
    }
    
    /// A mock implementation of an ``HTTPRequestor`` that returns the provided data and response when a request is made.
    ///
    /// - Parameters:
    ///   - data: The data to be returned after a request.
    ///   - response: The response to be returned after a request.
    ///   - delay: The time to wait before returning after a request has been made.
    /// - Returns: An ``HTTPRequestor``.
    static func mock(data: Data, response: HTTPURLResponse, delay: Duration = .zero) -> HTTPRequestor {
        HTTPRequestor { _ in
            try? await Task.sleep(for: delay)
            return (data, response)
        }
    }
    
    /// A mock implementation of an ``HTTPRequestor`` that throws an error when a request is made.
    ///
    /// - Parameters:
    ///   - error: The error to be thrown by any requests for data.
    ///   - delay: The time to wait before throwing, after a request has been made.
    /// - Returns: An ``HTTPRequestor``.
    static func mock(error: Error, delay: Duration = .zero) -> HTTPRequestor {
        HTTPRequestor { _ in
            try? await Task.sleep(for: delay)
            throw error
        }
    }
}
