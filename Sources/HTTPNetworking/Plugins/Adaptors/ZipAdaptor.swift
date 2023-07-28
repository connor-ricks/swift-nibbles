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
