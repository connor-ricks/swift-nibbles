import Foundation

// MARK: - StatusCodeValidatorError

/// An error representing a ``StatusCodeValidator`` that has failed.
public struct StatusCodeValidatorError: Error {
    /// The code that caused the failure.
    public let code: Int
}

// MARK: - StatusCodeValidator

/// An ``HTTPResponseValidator`` that can be used to validate a response's status code.
public struct StatusCodeValidator<S: Sequence>: HTTPResponseValidator where S.Iterator.Element == Int {
    
    // MARK: Properties
    
    /// The sequence of acceptable status codes for this validator.
    public let acceptableStatusCodes: S
    
    // MARK: Initializers
    
    /// Creates a ``StatusCodeValidator`` from the provided sequence of status codes.
    ///
    /// - Parameter acceptableStatusCodes: The sequence of acceptable status codes.
    public init(statusCode acceptableStatusCodes: S) {
        self.acceptableStatusCodes = acceptableStatusCodes
    }
    
    /// Creates a ``StatusCodeValidator`` from the provided status code.
    ///
    /// - Parameter statusCode: The acceptable status code.
    public init(statusCode: Int) where S == ClosedRange<Int> {
        self.acceptableStatusCodes = statusCode...statusCode
    }
    
    // MARK: HTTPResponseValidator
    
    public func validate(_ response: HTTPURLResponse, for request: URLRequest, with data: Data) async -> ValidationResult {
        if acceptableStatusCodes.contains(response.statusCode) {
            return .success
        } else {
            return .failure(StatusCodeValidatorError(code: response.statusCode))
        }
    }
}

// MARK: - HTTPRequest + StatusCodeValidator

extension HTTPRequest {
    /// Applies a ``StatusCodeValidator`` that validates the request's response has a status code within the provided sequence.
    @discardableResult
    public func validate<S: Sequence>(statusCode acceptableStatusCodes: S) -> Self where S.Iterator.Element == Int {
        validate(with: StatusCodeValidator(statusCode: acceptableStatusCodes))
    }
    
    /// Applies a ``StatusCodeValidator`` that validates the request's response has a status code matching the status code.
    @discardableResult
    public func validate(statusCode: Int) -> Self {
        validate(with: StatusCodeValidator(statusCode: statusCode))
    }
}

