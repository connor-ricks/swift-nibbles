@testable import Extensions
import XCTest

class ResultTests: XCTestCase {
    func test_staticSuccessResult_whereSuccessIsVoid_returnsSuccess() {
        let result: Result<Void, Never> = .success
        if case .failure = result {
            XCTFail("Expected static success member to have a .success result.")
        }
    }
}
