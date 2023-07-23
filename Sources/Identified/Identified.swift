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
