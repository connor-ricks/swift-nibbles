import Foundation

public typealias ValidationResult = Result<Void, Error>

/// An ``HTTPResponseValidator`` is used to validate the response from an ``HTTPRequest``.
///
/// By conforming to ``HTTPResponseValidator`` you can implement both simple and complex logic for validating
/// the response of an ``HTTPRequest``. Common use cases include validating the status code or headers of a response.
public protocol HTTPResponseValidator {
    func validate(_ response: HTTPURLResponse, for request: URLRequest, with data: Data) async -> ValidationResult
}
