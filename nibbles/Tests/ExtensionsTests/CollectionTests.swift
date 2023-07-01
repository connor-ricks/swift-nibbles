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

