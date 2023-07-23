import Foundation

// MARK: - AdaptationHandler

public typealias AdaptationHandler = (URLRequest, URLSession) async throws -> URLRequest

// MARK: - HTTPRequestAdaptor

/// An ``HTTPRequestAdaptor`` is used to change a `URLRequest` before it is sent out by an ``HTTPClient``.
///
/// By conforming to ``HTTPRequestAdaptor`` you can implement both simple and complex logic for manipulating a `URLRequest`
/// before it is sent out over the network. Common use cases include manage the client's authorization status, or adding additional headers to a request.
public protocol HTTPRequestAdaptor {
    func adapt(_ request: URLRequest, for session: URLSession) async throws -> URLRequest
}

// MARK: - HTTPRequestAdaptor + Adaptors

extension HTTPRequestAdaptor where Self == Adaptor {
    /// Creates an ``Adaptor`` from the provided ``AdaptationHandler``.
    public static func adapt(_ handler: @escaping AdaptationHandler) -> Adaptor {
        Adaptor(handler)
    }
}

extension HTTPRequestAdaptor where Self == ZipAdaptor {
    /// Creates a ``ZipAdaptor`` from the provided array of ``HTTPRequestAdaptor`` values.
    public static func zip(adaptors: [any HTTPRequestAdaptor]) -> ZipAdaptor {
        ZipAdaptor(adaptors)
    }
    
    /// Creates a ``ZipAdaptor`` from the provided variadic list of ``HTTPRequestAdaptor`` values.
    public static func zip(adaptors: any HTTPRequestAdaptor...) -> ZipAdaptor {
        ZipAdaptor(adaptors)
    }
}

// MARK: - Adaptor

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

// MARK: - ZipAdaptor

/// An ``HTTPRequestAdaptor`` that combines multiple adaptors into one, executing each adaptation in sequence.
public struct ZipAdaptor: HTTPRequestAdaptor {
    
    // MARK: Properties
    
    let adaptors: [any HTTPRequestAdaptor]
    
    // MARK: Initializers
    
    /// Creates a ``ZipAdaptor`` from the provided adaptors.
    ///
    /// - Parameter adaptors: The adaptors that should be executed in sequence.
    public init(_ adaptors: [any HTTPRequestAdaptor]) {
        self.adaptors = adaptors
    }
    
    /// Creates a ``ZipAdaptor`` from the provided adaptors.
    ///  
    /// - Parameter adaptors: The adaptors that should be executed in sequence.
    public init(_ adaptors: any HTTPRequestAdaptor...) {
        self.adaptors = adaptors
    }
    
    // MARK: RequestAdaptor
    
    public func adapt(_ request: URLRequest, for session: URLSession) async throws -> URLRequest {
        var request = request
        for adaptor in adaptors {
            request = try await adaptor.adapt(request, for: session)
        }
        
        return request
    }
}
