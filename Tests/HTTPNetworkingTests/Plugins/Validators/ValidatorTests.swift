@testable import HTTPNetworking
import XCTest

class ValidatorTests: XCTestCase {
    func test_validator_withProvidedHandler_callsHandlerOnValidation() async throws {
        
        let url = URL(string: "https://api.com")!
        let client = HTTPClient()
        let request = client.request(for: .get, to: url, expecting: String.self)
        let expectation = expectation(description: "Expected handler to be called.")
   
        let validator = Validator { _, _, _ in
            expectation.fulfill()
            return .success
        }
    
        _ = await validator.validate(HTTPURLResponse(), for: request.request, with: Data())
        await fulfillment(of: [expectation])
    }
    
    func test_request_validatorConvenience_isAddedToRequestValidators() async throws {
        let url = URL(string: "https://api.com")!
        let client = HTTPClient()
        let request = client.request(for: .get, to: url, expecting: String.self)
        let expectation = expectation(description: "Expected adaptor to be called.")
        request.validate { _, _, _ in
            expectation.fulfill()
            return .success
        }
        
        _ = try await request.validators.first?.validate(HTTPURLResponse(), for: request.request, with: Data())
        
        await fulfillment(of: [expectation])
    }
}
