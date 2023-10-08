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

@testable import Exchange
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
            do {
                _ = try await zipValidator.validate(HTTPURLResponse(), for: .mock, with: Data())
            } catch {
                XCTAssertTrue(error is CancellationError)
            }
        }
        
        await fulfillment(of: [validatorOneExpectation, validatorTwoExpectation], enforceOrder: true)
    }
    
    func test_zipValidator_validatorConvenience_isAddedToRequestValidators() async throws {
        let client = HTTPClient()
        let request = client.request(for: .get, to: .mock, expecting: String.self)
        let expectationOne = expectation(description: "Expected validator one to be called.")
        let expectationTwo = expectation(description: "Expected validator two to be called.")
        request.validate(zipping: [
            Validator { _, _, _ in
                expectationOne.fulfill()
                return .success
            },
            Validator { _, _, _ in
                expectationTwo.fulfill()
                return .success
            },
        ])
        
        _ = try await request.validators.first?.validate(HTTPURLResponse(), for: request.request, with: Data())
        
        await fulfillment(of: [expectationOne, expectationTwo], enforceOrder: true)
    }
}
