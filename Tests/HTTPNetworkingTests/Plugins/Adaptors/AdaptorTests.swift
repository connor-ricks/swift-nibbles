@testable import HTTPNetworking
import XCTest

class AdaptorTests: XCTestCase {
    func test_request_adaptorConvenience_isAddedToRequestAdaptors() async throws {
        let url = URL(string: "https://api.com")!
        let client = HTTPClient()
        let request = client.request(for: .get, to: url, expecting: String.self)
        let expectation = expectation(description: "Expected adaptor to be called.")
        request.adapt { request, _ in
            expectation.fulfill()
            return request
        }
        
        _ = try await request.adaptors.first?.adapt(request.request, for: client.dispatcher.session)
        
        await fulfillment(of: [expectation])
    }
}