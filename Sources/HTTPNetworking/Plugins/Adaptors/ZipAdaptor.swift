import Foundation

// MARK: - ZipAdaptor

/// An ``HTTPRequestAdaptor`` that combines multiple adaptors into one, executing each adaptation in sequence.
public struct ZipAdaptor: HTTPRequestAdaptor {
    
    // MARK: Properties
    
    /// An array of adaptors that make up this adaptor.
    public let adaptors: [any HTTPRequestAdaptor]
    
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
            try Task.checkCancellation()
            
            request = try await adaptor.adapt(request, for: session)
        }
        
        return request
    }
}

// MARK: - HTTPRequest + ZipAdaptor

extension HTTPRequest {
    /// Applies a ``ZipAdaptor`` that bundles up all the provided adaptors.
    @discardableResult
    public func adapt(zipping adaptors: [any HTTPRequestAdaptor]) -> Self {
        adapt(with: ZipAdaptor(adaptors))
    }
}
