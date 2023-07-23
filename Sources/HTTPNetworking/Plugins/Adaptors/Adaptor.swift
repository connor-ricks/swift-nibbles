import Foundation

public typealias AdaptationHandler = (URLRequest, URLSession) async throws -> URLRequest

/// An ``HTTPRequestAdaptor`` that can be used to manipulate a `URLRequest` before it is sent out over the network.
public struct Adaptor: HTTPRequestAdaptor {
    
    // MARK: Properties
    
    let handler: AdaptationHandler
    
    // MARK: Initializers
    
    /// Creates an ``Adaptor`` from the provided handler.
    ///
    /// - Parameter handler: The handler to execute when the ``Adaptor`` is asked to adapt a `URLRequest`
    public init(_ handler: @escaping AdaptationHandler) {
        self.handler = handler
    }
    
    // MARK: HTTPRequestAdaptor
    
    public func adapt(_ request: URLRequest, for session: URLSession) async throws -> URLRequest {
        try await handler(request, session)
    }
}
