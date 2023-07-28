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

class ArrayTests: XCTestCase {
    func test_chunkedArray_whenEmpty_returnsEmptyArray() {
        let array = [Int]()
        let chunks = array.chunked(into: 3)
        XCTAssertTrue(chunks.isEmpty)
    }
    
    func test_chunkedArray_whenChunkSizeDividesEvenly_returnsExpectedChunks() {
        let array = [1, 2, 3, 4, 5, 6]
        let expectedChunks = [[1, 2], [3, 4], [5, 6]]
        let chunks = array.chunked(into: 2)
        XCTAssertEqual(chunks, expectedChunks)
    }
    
    func test_chunkedArray_whenChunkSizeDoesNotDivideEvenly_returnsExpectedChunks() {
        let array = [1, 2, 3, 4, 5]
        let expectedChunks = [[1, 2], [3, 4], [5]]
        let chunks = array.chunked(into: 2)
        XCTAssertEqual(chunks, expectedChunks)
    }
    
    func test_chunkedArray_whenChunkSizeMatchesArray_returnsExpectedChunks() {
        let array = [1, 2, 3]
        let expectedChunks = [[1, 2, 3]]
        let chunks = array.chunked(into: 3)
        XCTAssertEqual(chunks, expectedChunks)
    }
    
    func test_chunkedArray_whenChunkSizeIsLargerThanArray_returnsExpectedChunks() {
        let array = [1, 2, 3]
        let expectedChunks = [[1, 2, 3]]
        let chunks = array.chunked(into: 4)
        XCTAssertEqual(chunks, expectedChunks)
    }
}
