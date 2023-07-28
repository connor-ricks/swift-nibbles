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

public typealias ValidationHandler = (
    _ response: HTTPURLResponse,
    _ request: URLRequest,
    _ data: Data
) async -> ValidationResult

/// An ``HTTPResponseValidator`` that can be used to validate a response from an ``HTTPRequest``.
public struct Validator: HTTPResponseValidator {
    
    // MARK: Properties
    
    private let handler: ValidationHandler
    
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
