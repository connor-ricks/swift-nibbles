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

class StatusCodeValidatorTests: XCTestCase {
    func test_statusCodeValidator_withSequenceOfStatusCodes_succeedsWhenCodeIsInRange() async {
        let validator = StatusCodeValidator(statusCode: 200...299)
        
        let lowerBoundResponse = HTTPURLResponse(url: .mock, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let lowerBoundResult = await validator.validate(lowerBoundResponse, for: .mock, with: Data())
        XCTAssertNoThrow(try lowerBoundResult.get())
        
        let withinBoundResponse = HTTPURLResponse(url: .mock, statusCode: 250, httpVersion: nil, headerFields: nil)!
        let withinBoundResult = await validator.validate(withinBoundResponse, for: .mock, with: Data())
        XCTAssertNoThrow(try withinBoundResult.get())
        
        let upperBoundResponse = HTTPURLResponse(url: .mock, statusCode: 299, httpVersion: nil, headerFields: nil)!
        let upperBoundResult = await validator.validate(upperBoundResponse, for: .mock, with: Data())
        XCTAssertNoThrow(try upperBoundResult.get())
    }
    
    func test_statusCodeValidator_withSequenceOfStatusCodes_failsWhenCodeIsOutOfRange() async {
        let validator = StatusCodeValidator(statusCode: 200...299)
        
        let lowerThanBoundResponse = HTTPURLResponse(url: .mock, statusCode: 199, httpVersion: nil, headerFields: nil)!
        let lowerThanBoundResult = await validator.validate(lowerThanBoundResponse, for: .mock, with: Data())
        XCTAssertThrowsError(try lowerThanBoundResult.get()) { error in
            XCTAssertEqual((error as? StatusCodeValidatorError)?.code, 199)
        }
        
        let higherThanBoundResponse = HTTPURLResponse(url: .mock, statusCode: 300, httpVersion: nil, headerFields: nil)!
        let heigherThanBoundResult = await validator.validate(higherThanBoundResponse, for: .mock, with: Data())
        XCTAssertThrowsError(try heigherThanBoundResult.get()) { error in
            XCTAssertEqual((error as? StatusCodeValidatorError)?.code, 300)
        }
    }
    
    func test_statusCodeValidator_withSingleStatusCode_succeedsWhenCodeIsInRange() async {
        let validator = StatusCodeValidator(statusCode: 200)
        
        let successfulResponse = HTTPURLResponse(url: .mock, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let successfulResult = await validator.validate(successfulResponse, for: .mock, with: Data())
        XCTAssertNoThrow(try successfulResult.get())
    }
    
    func test_statusCodeValidator_withSingleStatusCode_failsWhenCodeIsOutOfRange() async {
        let validator = StatusCodeValidator(statusCode: 200)
        
        let lowerThanBoundResponse = HTTPURLResponse(url: .mock, statusCode: 199, httpVersion: nil, headerFields: nil)!
        let lowerThanBoundResult = await validator.validate(lowerThanBoundResponse, for: .mock, with: Data())
        XCTAssertThrowsError(try lowerThanBoundResult.get()) { error in
            XCTAssertEqual((error as? StatusCodeValidatorError)?.code, 199)
        }
        
        let higherThanBoundResponse = HTTPURLResponse(url: .mock, statusCode: 201, httpVersion: nil, headerFields: nil)!
        let heigherThanBoundResult = await validator.validate(higherThanBoundResponse, for: .mock, with: Data())
        XCTAssertThrowsError(try heigherThanBoundResult.get()) { error in
            XCTAssertEqual((error as? StatusCodeValidatorError)?.code, 201)
        }
    }
    
    func test_request_singleStatusCodeValidationConvenience_isAddedToRequestValidators() async {
        let client = HTTPClient()
        let request = client.request(for: .get, to: .mock, expecting: String.self)
        request.validate(statusCode: 200)
        guard let validator = request.validators.first as? StatusCodeValidator<ClosedRange<Int>> else {
            XCTFail("Expected a ClosedRange<Int> StatusCodeValidator")
            return
        }
        
        XCTAssertEqual(validator.acceptableStatusCodes, 200...200)
    }
    
    func test_request_sequenceStatusCodeValidationConvenience_isAddedToRequestValidators() async {
        let client = HTTPClient()
        let request = client.request(for: .get, to: .mock, expecting: String.self)
        request.validate(statusCode: 200...299)
        guard let validator = request.validators.first as? StatusCodeValidator<ClosedRange<Int>> else {
            XCTFail("Expected a ClosedRange<Int> StatusCodeValidator")
            return
        }
        
        XCTAssertEqual(validator.acceptableStatusCodes, 200...299)
    }
}
