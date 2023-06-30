import Foundation

// MARK: - Identified

public protocol Identified {
    associatedtype IdentifierValue: Hashable
    var id: Identifier<Self, IdentifierValue> { get }
}

// MARK: - Identifier

public struct Identifier<Object, IdentifierValue: Hashable>: Hashable, Equatable {
    public let value: IdentifierValue
    
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

// MARK: - Identifier + Int

extension Identifier: ExpressibleByIntegerLiteral where IdentifierValue == Int {
    public typealias IntegerLiteralType = Int
    
    public init(integerLiteral value: Int) {
        self.value = value
    }
}

// MARK: - Identifier + String

extension Identifier: ExpressibleByStringLiteral,
                      ExpressibleByExtendedGraphemeClusterLiteral,
                      ExpressibleByUnicodeScalarLiteral where IdentifierValue == String {
    public typealias ExtendedGraphemeClusterLiteralType = String
    public typealias UnicodeScalarLiteralType = String
    
    public init(stringLiteral value: StaticString) {
        self.value = "\(value)"
    }
    
    public init(extendedGraphemeClusterLiteral value: String) {
        self.value = value
    }
}
