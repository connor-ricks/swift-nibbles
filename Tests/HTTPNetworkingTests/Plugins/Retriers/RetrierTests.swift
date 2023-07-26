@testable import HTTPNetworking
import XCTest

class RetrierTests: XCTestCase {
    func test_retrier_withProvidedHandler_callsHandlerOnRetry() async throws {
        
        let client = HTTPClient()
        let request = client.request(for: .get, to: .mock, expecting: String.self)
        let expectation = expectation(description: "Expected handler to be called.")
   
        let retrier = Retrier { _, _, _, _ in
            expectation.fulfill()
            return .concede
        }
    
        _ = try await retrier.retry(
            request.request,
            for: .shared,
            dueTo: URLError(.cannotParseResponse),
            previousAttempts: 0
        )
        await fulfillment(of: [expectation])
    }
    
    func test_request_retryConvenience_isAddedToRequestRetriers() async throws {
        struct MockError: Error {}
        
        let client = HTTPClient()
        let request = client.request(for: .get, to: .mock, expecting: String.self)
        let expectation = expectation(description: "Expected retrier to be called.")
        request.retry { _, _, _, _ in
            expectation.fulfill()
            return .concede
        }
        
        _ = try await request.retriers.first?.retry(
            request.request,
            for: client.dispatcher.session,
            dueTo: MockError(),
            previousAttempts: 0
        )
        
        await fulfillment(of: [expectation])
    }
}
