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

@testable import Extensions
import XCTest

class CollectionTests: XCTestCase {
    func test_safeAccess_whereIndexIsInsideBounds_returnsExpectedValue() {
        let array = [0, 1, 2, 3]
        XCTAssertEqual(array[safe: 2], 2)
    }
    
    func test_safeAccess_whereIndexIsAtLowerBound_returnsExpectedValue() {
        let array = [0, 1, 2, 3]
        XCTAssertEqual(array[safe: 0], 0)
    }
    
    func test_safeAccess_whereIndexIsAtUpperBound_returnsExpectedValue() {
        let array = [0, 1, 2, 3]
        XCTAssertEqual(array[safe: 3], 3)
    }
    
    func test_safeAccess_whereIndexIsLowerThanBounds_returnsNil() {
        let array = [0, 1, 2, 3]
        XCTAssertEqual(array[safe: -1], nil)
    }
    
    func test_safeAccess_whereIndexIsHigherThanBounds_returnsNil() {
        let array = [0, 1, 2, 3]
        XCTAssertEqual(array[safe: 4], nil)
    }
}

