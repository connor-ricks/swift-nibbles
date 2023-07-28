// MIT License
//
// Copyright (c) 2023 Connor Ricks
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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

