@testable import HTTPNetworking
import XCTest

class ZipValidatorTests: XCTestCase {
    func test_zipValidator_withValidators_containsValidatorsInOrder() {
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
    
    func test_zipValidator_whenCancelled_stopsIteratingThroughValidators() async {
        var task: Task<Void, Error>?
        let validatorOneExpectation = expectation(description: "Expected validator one to be executed.")
        let validatorTwoExpectation = expectation(description: "Expected validator two to be executed.")
        
        let zipValidator = ZipValidator([
            Validator { _, _, _ in
                validatorOneExpectation.fulfill()
                return .success
            },
            Validator { _, _, _ in
                validatorTwoExpectation.fulfill()
                task?.cancel()
                return .success
            },
            Validator { _, _, _ in
                XCTFail("Expected task to be cancelled and third validator to be skipped.")
                return .success
            }
        ])
        
        task = Task {
            let url = URL(string: "https://api.com")!
            do {
                _ = try await zipValidator.validate(HTTPURLResponse(), for: URLRequest(url: url), with: Data())
            } catch {
                XCTAssertTrue(error is CancellationError)
            }
        }
        
        await fulfillment(of: [validatorOneExpectation, validatorTwoExpectation])
    }
}
