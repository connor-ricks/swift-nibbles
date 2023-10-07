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

@testable import Stash
import XCTest

class StashTests: XCTestCase {
    func test_stash_validatingInsertionRetrievalAndDeletion() {
        let stash = Stash<String, Int>()
        stash.insert(1, forKey: "key")
        XCTAssertEqual(1, stash.value(forKey: "key"))
        XCTAssert(stash.keys.count == 1)
        stash.removeValue(forKey: "key")
        XCTAssertNil(stash.value(forKey:"key"))
        XCTAssert(stash.keys.count == 0)
    }
    
    func test_stash_whenInsertingDifferentValueWithSameKey_overwritesPreviousValue() {
        let stash = Stash<String, Int>()
        stash.insert(1, forKey: "key")
        XCTAssertEqual(1, stash.value(forKey: "key"))
        XCTAssert(stash.keys.count == 1)
        stash.insert(2, forKey: "key")
        XCTAssertEqual(2, stash.value(forKey:"key"))
        XCTAssert(stash.keys.count == 1)
    }

    func test_stash_validatingInsertionRetrievalAndDeletion_whenUsingSubscript() {
        let stash = Stash<String, Int>()
        stash["key"] = 1
        XCTAssertEqual(1, stash["key"])
        XCTAssert(stash.keys.count == 1)
        stash["key"] = nil
        XCTAssertNil(stash["key"])
        XCTAssert(stash.keys.count == 0)
    }

    func test_stash_whenAddingExpiredValue_valueIsRemovedFromStash() {
        let stash = Stash<String, Int>(lifetime: 0)
        stash.insert(1, forKey: "key")
        XCTAssertNil(stash.value(forKey:"key"))
        XCTAssert(stash.keys.count == 0)
    }

    func test_stash_whenAddingExpiredValueUsingSubscript_valueIsRemovedFromStash() {
        let stash = Stash<String, Int>(lifetime: 0)
        sleep(1)
        stash["key"] = 1
        XCTAssertNil(stash["key"])
        XCTAssert(stash.keys.count == 0)
    }

    func test_stash_whenSavedToDiskAndThenLoaded_isFullyRestored() throws {
        let stash = Stash<String, Int>()
        stash.insert(1, forKey: "key_1")
        stash.insert(2, forKey: "key_2")
        XCTAssert(stash.keys.count == 2)
        try stash.saveToDisk(withName: "test_stash")
        let newStash = try Stash.loadFromDisk(withName: "test_stash", keyType: String.self, valueType: Int.self)
        XCTAssertEqual(newStash["key_1"], 1)
        XCTAssertEqual(newStash["key_2"], 2)
        XCTAssert(newStash.keys.count == 2)
    }
    
    func test_wrappedKey_comparingSameTypesForEquality_returnsTrue() {
        let firstKey = Stash<Int, Data>.WrappedKey(1)
        let secondKey = Stash<Int, Data>.WrappedKey(1)
        
        XCTAssertTrue(firstKey.isEqual(secondKey))
    }
    
    func test_wrappedKey_comparingDifferentTypesForEquality_returnsFalse() {
        let intKey = Stash<Int, Data>.WrappedKey(1)
        let stringKey = Stash<String, Data>.WrappedKey("1")
        
        XCTAssertFalse(intKey.isEqual(stringKey))
        XCTAssertFalse(intKey.isEqual(nil))
        XCTAssertFalse(intKey.isEqual(1))
        XCTAssertFalse(intKey.isEqual("1"))
    }
}
