import XCTest

extension XCTestCase {
    public static func runWithinSuite() {
        XCTestSuite(forTestCaseClass: Self.self).run()
    }
}

