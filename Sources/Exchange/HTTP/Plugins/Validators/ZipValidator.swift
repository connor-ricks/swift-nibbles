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

// MARK: - ZipValidator

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
    
    public func validate(_ response: HTTPURLResponse, for request: URLRequest, with data: Data) async -> ValidationResult {
        for validator in validators {
            do { try Task.checkCancellation() }
            catch { return .failure(error) }
            
            if case .failure(let error) = await validator.validate(response, for: request, with: data) {
                return .failure(error)
            }
        }
        
        return .success
    }
}

// MARK: - HTTPRequest + ZipValidator

extension HTTPRequest {
    /// Applies a ``ZipValidator`` that bundles up all the provided validators.
    public func validate(zipping validators: [any HTTPResponseValidator]) -> Self {
        validate(with: ZipValidator(validators))
    }
}
