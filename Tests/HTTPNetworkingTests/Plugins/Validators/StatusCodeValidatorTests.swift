@testable import HTTPNetworking
import XCTest

class StatusCodeValidatorTests: XCTestCase {
    func test_statusCodeValidator_withSequenceOfStatusCodes_succeedsWhenCodeIsInRange() async {
        let url = URL(string: "https://api.com")!
        let request = URLRequest(url: url)
        let validator = StatusCodeValidator(statusCode: 200...299)
        
        let lowerBoundResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let lowerBoundResult = await validator.validate(lowerBoundResponse, for: request, with: Data())
        XCTAssertNoThrow(try lowerBoundResult.get())
        
        let withinBoundResponse = HTTPURLResponse(url: url, statusCode: 250, httpVersion: nil, headerFields: nil)!
        let withinBoundResult = await validator.validate(withinBoundResponse, for: request, with: Data())
        XCTAssertNoThrow(try withinBoundResult.get())
        
        let upperBoundResponse = HTTPURLResponse(url: url, statusCode: 299, httpVersion: nil, headerFields: nil)!
        let upperBoundResult = await validator.validate(upperBoundResponse, for: request, with: Data())
        XCTAssertNoThrow(try upperBoundResult.get())
    }
    
    func test_statusCodeValidator_withSequenceOfStatusCodes_failsWhenCodeIsOutOfRange() async {
        let url = URL(string: "https://api.com")!
        let request = URLRequest(url: url)
        let validator = StatusCodeValidator(statusCode: 200...299)
        
        let lowerThanBoundResponse = HTTPURLResponse(url: url, statusCode: 199, httpVersion: nil, headerFields: nil)!
        let lowerThanBoundResult = await validator.validate(lowerThanBoundResponse, for: request, with: Data())
        XCTAssertThrowsError(try lowerThanBoundResult.get()) { error in
            XCTAssertEqual((error as? StatusCodeValidatorError)?.code, 199)
        }
        
        let higherThanBoundResponse = HTTPURLResponse(url: url, statusCode: 300, httpVersion: nil, headerFields: nil)!
        let heigherThanBoundResult = await validator.validate(higherThanBoundResponse, for: request, with: Data())
        XCTAssertThrowsError(try heigherThanBoundResult.get()) { error in
            XCTAssertEqual((error as? StatusCodeValidatorError)?.code, 300)
        }
    }
    
    func test_statusCodeValidator_withSingleStatusCode_succeedsWhenCodeIsInRange() async {
        let url = URL(string: "https://api.com")!
        let request = URLRequest(url: url)
        let validator = StatusCodeValidator(statusCode: 200)
        
        let successfulResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let successfulResult = await validator.validate(successfulResponse, for: request, with: Data())
        XCTAssertNoThrow(try successfulResult.get())
    }
    
    func test_statusCodeValidator_withSingleStatusCode_failsWhenCodeIsOutOfRange() async {
        let url = URL(string: "https://api.com")!
        let request = URLRequest(url: url)
        let validator = StatusCodeValidator(statusCode: 200)
        
        let lowerThanBoundResponse = HTTPURLResponse(url: url, statusCode: 199, httpVersion: nil, headerFields: nil)!
        let lowerThanBoundResult = await validator.validate(lowerThanBoundResponse, for: request, with: Data())
        XCTAssertThrowsError(try lowerThanBoundResult.get()) { error in
            XCTAssertEqual((error as? StatusCodeValidatorError)?.code, 199)
        }
        
        let higherThanBoundResponse = HTTPURLResponse(url: url, statusCode: 201, httpVersion: nil, headerFields: nil)!
        let heigherThanBoundResult = await validator.validate(higherThanBoundResponse, for: request, with: Data())
        XCTAssertThrowsError(try heigherThanBoundResult.get()) { error in
            XCTAssertEqual((error as? StatusCodeValidatorError)?.code, 201)
        }
    }
    
    func test_request_singleStatusCodeValidationConvenience_isAddedToRequestValidators() async {
        let url = URL(string: "https://api.com")!
        let client = HTTPClient()
        let request = client.request(for: .get, to: url, expecting: String.self)
        request.validate(statusCode: 200)
        guard let validator = request.validators.first as? StatusCodeValidator<ClosedRange<Int>> else {
            XCTFail("Expected a ClosedRange<Int> StatusCodeValidator")
            return
        }
        
        XCTAssertEqual(validator.acceptableStatusCodes, 200...200)
    }
    
    func test_request_sequenceStatusCodeValidationConvenience_isAddedToRequestValidators() async {
        let url = URL(string: "https://api.com")!
        let client = HTTPClient()
        let request = client.request(for: .get, to: url, expecting: String.self)
        request.validate(statusCode: 200...299)
        guard let validator = request.validators.first as? StatusCodeValidator<ClosedRange<Int>> else {
            XCTFail("Expected a ClosedRange<Int> StatusCodeValidator")
            return
        }
        
        XCTAssertEqual(validator.acceptableStatusCodes, 200...299)
    }
}
