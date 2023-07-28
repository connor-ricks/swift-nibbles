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

@testable import Identified
import XCTest

class IdentifiedTests: XCTestCase {
    
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

