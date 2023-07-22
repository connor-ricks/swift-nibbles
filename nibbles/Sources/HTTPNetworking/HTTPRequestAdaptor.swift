import Foundation

// MARK: - AdaptationHandler

public typealias AdaptationHandler = (URLRequest, URLSession) async throws -> URLRequest

// MARK: - HTTPRequestAdaptor

public protocol HTTPRequestAdaptor {
    func adapt(_ request: URLRequest, for session: URLSession) async throws -> URLRequest
}

// MARK: - HTTPRequestAdaptor + Adaptors

extension HTTPRequestAdaptor where Self == Adaptor {
    public static func adapt(_ handler: @escaping AdaptationHandler) -> HTTPRequestAdaptor {
        Adaptor(handler)
    }
}

extension HTTPRequestAdaptor where Self == ZipAdaptor {
    public static func zip(adaptors: [any HTTPRequestAdaptor]) -> HTTPRequestAdaptor {
        ZipAdaptor(adaptors)
    }
    
    public static func zip(adaptors: any HTTPRequestAdaptor...) -> HTTPRequestAdaptor {
        ZipAdaptor(adaptors)
    }
}

// MARK: - Adaptor

public struct Adaptor: HTTPRequestAdaptor {
    
    // MARK: Properties
    
    let handler: AdaptationHandler
    
    // MARK: Initializers
    
    public init(_ handler: @escaping AdaptationHandler) {
        self.handler = handler
    }
    
    // MARK: HTTPRequestAdaptor
    
    public func adapt(_ request: URLRequest, for session: URLSession) async throws -> URLRequest {
        try await handler(request, session)
    }
}

// MARK: - ZipAdaptor

public struct ZipAdaptor: HTTPRequestAdaptor {
    
    // MARK: Properties
    
    let adaptors: [any HTTPRequestAdaptor]
    
    // MARK: Initializers
    
    public init(_ adaptors: [any HTTPRequestAdaptor]) {
        self.adaptors = adaptors
    }
    
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
