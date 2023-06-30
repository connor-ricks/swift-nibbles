import SwiftUI
import XCTest

public class HTTPNetworkerTests: XCTestCase {
    
    // MARK: MockError
    
    struct MockError: Error, Equatable {
        let id: Int
    }
    
    // MARK: Properties
    
    let url = URL(string: "https://hello-world.com")!
    
    let strings = ["Hello", "World", "!"]
    
    var data: Data {
        try! JSONEncoder().encode(strings)
    }

    // MARK: Success Tests
    
    func test_performingRequest_whereResponseIsSuccessful_returnsExpectedResponse() async throws {
        // Lower success status code boundary
        let networker1 = HTTPNetworker(requestor: .mock(data: data, response: createResponse(with: 200)))
        let response1 = try await networker1.perform(.get, to: url, expecting: [String].self)
        XCTAssertEqual(response1, strings)

        // Upper success status code boundary
        let networker2 = HTTPNetworker(requestor: .mock(data: data, response: createResponse(with: 399)))
        let response2 = try await networker2.perform(.get, to: url, expecting: [String].self)
        XCTAssertEqual(response2, strings)
    }
    
    func test_performingRequest_withBodyWhereResponseIsSuccessful_returnsExpectedResponse() async throws {
        // Lower success status code boundary
        let networker1 = HTTPNetworker(requestor: .mock(data: data, response: createResponse(with: 200)))
        let response1 = try await networker1.perform(.post, to: url, with: strings.reversed(), expecting: [String].self)
        XCTAssertEqual(response1, strings)

        // Upper success status code boundary
        let networker2 = HTTPNetworker(requestor: .mock(data: data, response: createResponse(with: 399)))
        let response2 = try await networker2.perform(.post, to: url, with: strings.reversed(), expecting: [String].self)
        XCTAssertEqual(response2, strings)
    }
    
    // MARK: Failure Tests
    
    func test_performingRequest_whereResponseIsUnsuccessfulDueToStatusCode_throwsExpectedError() async throws {
        // Lower failure status code boundary
        let lowerBoundCode = 199
        do {
            let networker = HTTPNetworker(requestor: .mock(data: data, response: createResponse(with: lowerBoundCode)))
            _ = try await networker.perform(.get, to: url, expecting: [String].self)
            XCTFail("Expected request to fail due to the status code.")
        } catch let error as HTTPFailure {
            XCTAssertEqual(error.code, lowerBoundCode)
        }
        
        // Upper failure status code boundary
        let upperBoundCode = 400
        do {
            let networker = HTTPNetworker(requestor: .mock(data: data, response: createResponse(with: upperBoundCode)))
            _ = try await networker.perform(.get, to: url, expecting: [String].self)
            XCTFail("Expected request to fail due to the status code.")
        } catch let error as HTTPFailure {
            XCTAssertEqual(error.code, upperBoundCode)
        }
    }
    
    func test_performingRequest_whereResponseIsUnsuccessfulDueToRequestorError_throwsExpectedError() async throws {
        let expectedError = MockError(id: 1)
        do {
            let networker = HTTPNetworker(requestor: .mock(error: expectedError))
            _ = try await networker.perform(.get, to: url, expecting: [String].self)
            XCTFail("Expected request to fail due to requestor error.")
        } catch let error as MockError {
            XCTAssertEqual(error, expectedError)
        }
    }
    
    func test_performingRequest_whereResponseIsUnsuccessfulDueToDecodingError_throwsExpectedError() async throws {
        let expectation = XCTestExpectation(description: "Expect a decoding error to be thrown.")
        do {
            let networker = HTTPNetworker(requestor: .mock(data: data, response: createResponse(with: 200)))
            _ = try await networker.perform(.get, to: url, expecting: Int.self)
            XCTFail("Expected request to fail due to requestor error.")
        } catch _ as DecodingError {
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation])
    }
    
    // MARK: URLRequest Validation Tests
    
    func test_performingRequest_sendsOutURLRequest_withExpectedData() async throws {
        let expectation = XCTestExpectation(description: "Expected mock requestor closure to be called.")
        
        let method = HTTPMethod.patch
        let headers = ["HEADER-1": "Networker-1", "HEADER-2": "Networker-2"]
        let additionalHeaders = ["HEADER-1": "Additional-1", "HEADER-3": "Additional-3"]
        var expectedRequest = URLRequest(url: url)
        expectedRequest.httpMethod = method.rawValue
        expectedRequest.httpBody = nil
        expectedRequest.allHTTPHeaderFields = headers.merging(additionalHeaders, uniquingKeysWith: { $1 })
        
        let networker = HTTPNetworker(headers: headers, requestor: HTTPRequestor { request in
            XCTAssertEqual(request, expectedRequest)
            expectation.fulfill()
            return (self.data, self.createResponse(with: 200))
        })
        
        _ = try await networker.perform(method, to: url, expecting: [String].self, additionalHeaders: additionalHeaders)
        
        await fulfillment(of: [expectation])
    }
    
    // MARK: Helpers
     
    func createResponse(with code: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: code, httpVersion: nil, headerFields: [:])!
    }
}
