import Foundation

// MARK: - AdaptationHandler

public typealias AdaptationHandler = (
    _ request: URLRequest,
    _ session: URLSession
) async throws -> URLRequest

// MARK: - Adaptor

/// An ``HTTPRequestAdaptor`` that can be used to manipulate a `URLRequest` before it is sent out over the network.
public struct Adaptor: HTTPRequestAdaptor {
    
    // MARK: Properties
    
    private let handler: AdaptationHandler
    
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

// MARK: - HTTPRequest + Adaptor

extension HTTPRequest {
    /// Applies an ``Adaptor`` that handles request adaptation using the provided ``AdaptationHandler``.
    @discardableResult
    public func adapt(_ handler: @escaping AdaptationHandler) -> Self {
        adapt(with: Adaptor(handler))
    }
}
