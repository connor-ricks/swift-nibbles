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
