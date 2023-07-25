@testable import HTTPNetworking
import XCTest

class ParametersAdaptorTests: XCTestCase {
    func test_parametersAdaptor_withPrameters_addsParametersToRequest() async throws {
        let adaptor = ParametersAdaptor(items: [
            .init(name: "one-name", value: "one-value"),
            .init(name: "two-name", value: "two-value"),
        ])
        
        let cleanUrlRequest = URLRequest(url: URL(string: "https://api.com")!)
        let adaptedCleanUrlRequest = try await adaptor.adapt(cleanUrlRequest, for: .shared)
        XCTAssertEqual(
            adaptedCleanUrlRequest.url,
            URL(string: "https://api.com?one-name=one-value&two-name=two-value")!
        )
        
        let dirtyUrlRequest = URLRequest(url: URL(string: "https://api.com?")!)
        let adaptedDirtyUrlRequest = try await adaptor.adapt(dirtyUrlRequest, for: .shared)
        XCTAssertEqual(
            adaptedDirtyUrlRequest.url,
            URL(string: "https://api.com?one-name=one-value&two-name=two-value")!
        )
        
        let existingParametersUrlRequest = URLRequest(url: URL(string: "https://api.com?two-name=original-two-value&other-name=other-value")!)
        let adaptedExistingParametersUrlRequest = try await adaptor.adapt(existingParametersUrlRequest, for: .shared)
        XCTAssertEqual(
            adaptedExistingParametersUrlRequest.url,
            URL(string: "https://api.com?two-name=original-two-value&other-name=other-value&one-name=one-value&two-name=two-value")!
        )
    }
    
    func test_request_adaptorConvenience_isAddedToRequestAdaptors() async throws {
        let url = URL(string: "https://api.com")!
        let client = HTTPClient()
        let request = client.request(for: .get, to: url, expecting: String.self)
        
        let items: [URLQueryItem] = [
            .init(name: "one-name", value: "one-value"),
            .init(name: "two-name", value: "two-value"),
        ]
        request.adapt(queryItems: items)
        
        guard let adaptor = request.adaptors.first as? ParametersAdaptor else {
            XCTFail("Expected request to container PrametersAdaptor.")
            return
        }
        
        XCTAssertEqual(adaptor.items, items)
    }
}
