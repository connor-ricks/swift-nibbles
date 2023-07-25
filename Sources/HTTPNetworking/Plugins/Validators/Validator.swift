import Foundation

public typealias ValidationHandler = (HTTPURLResponse, URLRequest, Data) async -> ValidationResult

/// An ``HTTPResponseValidator`` that can be used to validate a response from an ``HTTPRequest``.
public struct Validator: HTTPResponseValidator {
    
    // MARK: Properties
    
    let handler: ValidationHandler
    
    // MARK: Initializers
    
    /// Creates a ``Validator`` from the provided handler.
    ///
    /// - Parameter handler: The handler to execute when the ``Validator`` is asked to validate a response.
    public init(_ handler: @escaping ValidationHandler) {
        self.handler = handler
    }
    
    // MARK: HTTPResponseValidator
    
    public func validate(_ response: HTTPURLResponse, for request: URLRequest, with data: Data) async -> ValidationResult {
        await handler(response, request, data)
    }
}

// MARK: - HTTPRequest + Validator

extension HTTPRequest {
    /// Applies a ``Validator`` that validates the request's response using the provided ``ValidationHandler``.
    @discardableResult
    public func validate(_ handler: @escaping ValidationHandler) -> Self {
        validate(with: Validator(handler))
    }
}
