import Foundation
import XCTest

public class IdentifiedTests: XCTestCase {
    
    // MARK: Dog
    
    struct Dog: Identified, Codable {
        var id: Identifier<Self, Int>
    }
    
    // MARK: Tests
    
    func test_identifierValue_whenCreated_matchesExpectation() {
        let dog = Dog(id: .init(value: 1))
        XCTAssertEqual(dog.id.value, 1)
    }
    
    func test_identifierValue_whenDecoded_matchesExpectation() throws {
        let data = #"{ "id": 1 }"#.data(using: .utf8)!
        let decoder = JSONDecoder()
        let dog = try decoder.decode(Dog.self, from: data)
        XCTAssertEqual(dog.id.value, 1)
    }
    
    func test_identifierValue_whenEncoded_matchesExpectation() throws {
        let dog = Dog(id: .init(value: 1))
        let encoder = JSONEncoder()
        let data = try encoder.encode(dog)
        XCTAssertEqual(data, #"{"id":1}"#.data(using: .utf8)!)
    }
}

