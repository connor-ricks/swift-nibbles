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

// MARK: - Identified

/// An object that is uniquely identifiable.
public protocol Identified {
    associatedtype IdentifierValue: Hashable
    var id: Identifier<Self, IdentifierValue> { get }
}

// MARK: - Identifier

/// An identified that identifies a particular object type.
public struct Identifier<Object, IdentifierValue: Hashable>: Hashable, Equatable {
    
    /// The underlying value of the identified.
    public let value: IdentifierValue
    
    /// Creates an identified backed by the provided value.
    ///
    /// - Parameter value: The value that backs this identified.
    public init(value: IdentifierValue) {
        self.value = value
    }
}

// MARK: - Identifier + Decodable

extension Identifier: Decodable where IdentifierValue: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode(IdentifierValue.self)
    }
}

// MARK: - Identifier + Encodable

extension Identifier: Encodable where IdentifierValue: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
