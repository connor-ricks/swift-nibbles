import Foundation

// MARK: - ValidationResult

public typealias ValidationResult = Result<Void, Error>

// MARK: - ValidationHandler

public typealias ValidationHandler = (HTTPURLResponse, URLRequest, Data) async -> ValidationResult

// MARK: - HTTPResponseValidator

public protocol HTTPResponseValidator {
    func validate(_ response: HTTPURLResponse, for request: URLRequest, with data: Data) async -> ValidationResult
}

// MARK: - HTTPResponseValidator + Validators

extension HTTPResponseValidator where Self == Validator {
    public static func validate(_ handler: @escaping ValidationHandler) -> HTTPResponseValidator {
        Validator(handler)
    }
}
 
extension HTTPResponseValidator where Self == ZipValidator {
    public static func zip(validators: [any HTTPResponseValidator]) -> HTTPResponseValidator {
        ZipValidator(validators)
    }
    
    public static func zip(validators: any HTTPResponseValidator...) -> HTTPResponseValidator {
        ZipValidator(validators)
    }
}

// MARK: - Validator

public struct Validator: HTTPResponseValidator {
    
    // MARK: Properties
    
    let handler: ValidationHandler
    
    // MARK: Initializers
    
    public init(_ handler: @escaping ValidationHandler) {
        self.handler = handler
    }
    
    // MARK: HTTPResponseValidator
    
    public func validate(_ response: HTTPURLResponse, for request: URLRequest, with data: Data) async -> ValidationResult {
        await handler(response, request, data)
    }
}

// MARK: - ZipValidator

public struct ZipValidator: HTTPResponseValidator {
    
    // MARK: Properties
    
    let validators: [any HTTPResponseValidator]
    
    // MARK: Initializers
    
    public init(_ validators: [any HTTPResponseValidator]) {
        self.validators = validators
    }
    
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

