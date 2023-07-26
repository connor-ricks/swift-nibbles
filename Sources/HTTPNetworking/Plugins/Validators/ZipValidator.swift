import Foundation

/// An ``HTTPResponseValidator`` that combines multiple validators into one, executing each validation in sequence.
public struct ZipValidator: HTTPResponseValidator {
    
    // MARK: Properties
    
    /// An array of validators that make up this validator.
    public let validators: [any HTTPResponseValidator]
    
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
    
    public func validate(_ response: HTTPURLResponse, for request: URLRequest, with data: Data) async throws -> ValidationResult {
        for validator in validators {
            try Task.checkCancellation()
            
            if case .failure(let error) = try await validator.validate(response, for: request, with: data) {
                return .failure(error)
            }
        }
        
        return .success
    }
}
