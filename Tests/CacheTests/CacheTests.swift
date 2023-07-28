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

@testable import Cache
import XCTest

class CacheTests: XCTestCase {
    func test_cache_validatingInsertionRetrievalAndDeletion() {
        let cache = Cache<String, Int>()
        cache.insert(1, forKey: "key")
        XCTAssertEqual(1, cache.value(forKey: "key"))
        XCTAssert(cache.keys.count == 1)
        cache.removeValue(forKey: "key")
        XCTAssertNil(cache.value(forKey:"key"))
        XCTAssert(cache.keys.count == 0)
    }
    
    func test_cache_whenInsertingDifferentValueWithSameKey_overwritesPreviousValue() {
        let cache = Cache<String, Int>()
        cache.insert(1, forKey: "key")
        XCTAssertEqual(1, cache.value(forKey: "key"))
        XCTAssert(cache.keys.count == 1)
        cache.insert(2, forKey: "key")
        XCTAssertEqual(2, cache.value(forKey:"key"))
        XCTAssert(cache.keys.count == 1)
    }

    func test_cache_validatingInsertionRetrievalAndDeletion_whenUsingSubscript() {
        let cache = Cache<String, Int>()
        cache["key"] = 1
        XCTAssertEqual(1, cache["key"])
        XCTAssert(cache.keys.count == 1)
        cache["key"] = nil
        XCTAssertNil(cache["key"])
        XCTAssert(cache.keys.count == 0)
    }

    func test_cache_whenAddingExpiredValue_valueIsRemovedFromCache() {
        let cache = Cache<String, Int>(lifetime: 0)
        cache.insert(1, forKey: "key")
        XCTAssertNil(cache.value(forKey:"key"))
        XCTAssert(cache.keys.count == 0)
    }

    func test_cache_whenAddingExpiredValueUsingSubscript_valueIsRemovedFromCache() {
        let cache = Cache<String, Int>(lifetime: 0)
        sleep(1)
        cache["key"] = 1
        XCTAssertNil(cache["key"])
        XCTAssert(cache.keys.count == 0)
    }

    func test_cache_whenSavedToDiskAndThenLoaded_isFullyRestored() throws {
        let cache = Cache<String, Int>()
        cache.insert(1, forKey: "key_1")
        cache.insert(2, forKey: "key_2")
        XCTAssert(cache.keys.count == 2)
        try cache.saveToDisk(withName: "test_cache")
        let newCache = try Cache.loadFromDisk(withName: "test_cache", keyType: String.self, valueType: Int.self)
        XCTAssertEqual(newCache["key_1"], 1)
        XCTAssertEqual(newCache["key_2"], 2)
        XCTAssert(newCache.keys.count == 2)
    }
    
    func test_wrappedKey_comparingSameTypesForEquality_returnsTrue() {
        let firstKey = Cache<Int, Data>.WrappedKey(1)
        let secondKey = Cache<Int, Data>.WrappedKey(1)
        
        XCTAssertTrue(firstKey.isEqual(secondKey))
    }
    
    func test_wrappedKey_comparingDifferentTypesForEquality_returnsFalse() {
        let intKey = Cache<Int, Data>.WrappedKey(1)
        let stringKey = Cache<String, Data>.WrappedKey("1")
        
        XCTAssertFalse(intKey.isEqual(stringKey))
        XCTAssertFalse(intKey.isEqual(nil))
        XCTAssertFalse(intKey.isEqual(1))
        XCTAssertFalse(intKey.isEqual("1"))
    }
}
