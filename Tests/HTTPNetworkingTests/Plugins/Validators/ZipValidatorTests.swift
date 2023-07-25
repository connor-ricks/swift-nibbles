@testable import HTTPNetworking
import XCTest

class ZipValidatorTests: XCTestCase {
    func test_zippedValidator_withValidators_containsValidatorsInOrder() {
        struct TestValidator: HTTPResponseValidator, Equatable {
            let id: Int
            func validate(_ response: HTTPURLResponse, for request: URLRequest, with data: Data) async -> ValidationResult {
                .success
            }
        }
        
        let one = TestValidator(id: 1)
        let two = TestValidator(id: 1)
        let three = TestValidator(id: 1)
        let expectedValidators = [one, two, three]
        
        let zipValidator = ZipValidator(expectedValidators)
        XCTAssertEqual(zipValidator.validators as? [TestValidator], expectedValidators)
        
        let variadicZip = ZipValidator(one, two, three)
        XCTAssertEqual(variadicZip.validators as? [TestValidator], expectedValidators)
    }
}
