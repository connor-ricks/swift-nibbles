import Foundation

/// An ``HTTPRequestAdaptor`` that can be used to append query parameters to a request before it is sent out over the network.
///
/// > Warning: This adaptor will **not** overwrite existing parameters, instead it will append to existing parameters.
public struct ParametersAdaptor: HTTPRequestAdaptor {
    
    // MARK: Properties
    
    let items: [URLQueryItem]
    
    // MARK: Initializers
    
    /// Creates a ``ParametersAdaptor`` from the provided query parameters.
    ///
    /// - Parameter items: The query parameters to append to incoming requests.
    public init(items: [URLQueryItem]) {
        self.items = items
    }
    
    // MARK: HTTPRequestAdaptor
    
    public func adapt(_ request: URLRequest, for session: URLSession) async throws -> URLRequest {
        var request = request
        guard let url = request.url else {
            preconditionFailure("URLRequest should contain a valid URL at this point.")
        }
        
        request.url = url.appending(queryItems: items)
        return request
    }
}

// MARK: - HTTPRequest + ParametersAdaptor

extension HTTPRequest {
    /// Applies a ``ParametersAdaptor`` that appends the provided query parameters to the request.
    @discardableResult
    public func adapt(queryItems: [URLQueryItem]) -> Self {
        adapt(with: ParametersAdaptor(items: queryItems))
    }
}
