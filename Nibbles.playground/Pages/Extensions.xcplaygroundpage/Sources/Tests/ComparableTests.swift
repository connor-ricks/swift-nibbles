import Foundation
import XCTest

public class ComparableTests: XCTestCase {
    func test_clamp_whenValueInsideLimits_returnsValue() {
        XCTAssertEqual(4.clamped(to: 2...5), 4)
    }
    
    func test_clamp_whenValueLowerThanLimits_returnsLowerBound() {
        XCTAssertEqual(0.clamped(to: 2...5), 2)
    }
    
    func test_clamp_whenValueHigherThanLimits_returnsHigherBound() {
        XCTAssertEqual(10.clamped(to: 2...5), 5)
    }
}
