import Foundation

// MARK: - ValidationResult

public typealias ValidationResult = Result<Void, Error>

// MARK: - ValidationHandler

public typealias ValidationHandler = (HTTPURLResponse, URLRequest, Data) async -> ValidationResult

// MARK: - HTTPResponseValidator

/// An ``HTTPResponseValidator`` is used to validate the response from an ``HTTPRequest``.
///
/// By conforming to ``HTTPResponseValidator`` you can implement both simple and complex logic for validating
/// the response of an ``HTTPRequest``. Common use cases include validating the status code or headers of a response.
public protocol HTTPResponseValidator {
    func validate(_ response: HTTPURLResponse, for request: URLRequest, with data: Data) async -> ValidationResult
}

// MARK: - HTTPResponseValidator + Validators

extension HTTPResponseValidator where Self == Validator {
    /// Creates a ``Validator`` from the provided ``ValidationHandler``.
    public static func validate(_ handler: @escaping ValidationHandler) -> Validator {
        Validator(handler)
    }
}
 
extension HTTPResponseValidator where Self == ZipValidator {
    /// Creates a ``ZipValidator`` from the provided array of ``HTTPResponseValidator`` values.
    public static func zip(validators: [any HTTPResponseValidator]) -> ZipValidator {
        ZipValidator(validators)
    }
    
    /// Creates a ``ZipValidator`` from the provided variadic list of ``HTTPResponseValidator`` values.
    public static func zip(validators: any HTTPResponseValidator...) -> ZipValidator {
        ZipValidator(validators)
    }
}

// MARK: - Validator

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

// MARK: - ZipValidator

/// An ``HTTPResponseValidator`` that combines multiple validators into one, executing each validation in sequence.
public struct ZipValidator: HTTPResponseValidator {
    
    // MARK: Properties
    
    let validators: [any HTTPResponseValidator]
    
    // MARK: Initializers
    
    /// Creates a ``ZipValidator`` from the provided validators
    ///
    /// - Parameter validators: The validators that should be executed in sequence.
    public init(_ validators: [any HTTPResponseValidator]) {
        self.validators = validators
    }
    
    /// Creates a ``ZipValidator`` from the provided validators
    ///
    /// - Parameter validators: The validators that should be executed in sequence.
    public init(_ validators: any HTTPResponseValidator...) {
        self.validators = validators
    }
    
    // MARK: ResponseValidator
    
    public func validate(_ response: HTTPURLResponse, for request: URLRequest, with data: Data) async -> ValidationResult {
        for validator in validators {
            if case .failure(let error) = await validator.validate(response, for: request, with: data) {
                return .failure(error)
            }
        }
        
        return .success
    }
}

// MARK: - Result + Success

extension Result where Success == Void {
    public static var success: Result<Success, Failure> {
        return .success(())
    }
}

