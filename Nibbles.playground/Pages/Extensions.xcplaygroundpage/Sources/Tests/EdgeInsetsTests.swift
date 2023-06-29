import SwiftUI
import XCTest

public class EdgeInsetsTests: XCTestCase {
    func test_zeroStaticProperty_initializesCorrectInsets() {
        let expected = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        let actual = EdgeInsets.zero
        XCTAssertEqual(expected, actual)
    }

    func test_singleInsetInitializer_initializesCorrectInsets() {
        let expected = EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        let actual = EdgeInsets(padding: 10)
        XCTAssertEqual(expected, actual)
    }

    func test_axisInsetsInitializer_initializesCorrectInsets() {
        let expected = EdgeInsets(top: 10, leading: 5, bottom: 10, trailing: 5)
        let actual = EdgeInsets.init(vertical: 10, horizontal: 5)
        XCTAssertEqual(expected, actual)
    }
}
