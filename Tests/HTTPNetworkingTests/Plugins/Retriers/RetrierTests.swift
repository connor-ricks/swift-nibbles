@testable import HTTPNetworking
import XCTest

class RetrierTests: XCTestCase {
    func test_request_retryConvenience_isAddedToRequestRetriers() async {
        struct MockError: Error {}
        
        let url = URL(string: "https://api.com")!
        let client = HTTPClient()
        let request = client.request(for: .get, to: url, expecting: String.self)
        let expectation = expectation(description: "Expected retrier to be called.")
        request.retry { _, _, _ in
            expectation.fulfill()
            return .concede
        }
        
        _ = await request.retriers.first?.retry(
            request.request,
            for: client.dispatcher.session,
            dueTo: MockError()
        )
        
        await fulfillment(of: [expectation])
    }
}