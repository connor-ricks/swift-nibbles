@testable import HTTPNetworking
import XCTest

class ParametersAdaptorTests: XCTestCase {
    func test_parametersAdaptor_withPrameters_addsParametersToRequest() async throws {
        let items: [URLQueryItem] = [
            .init(name: "one-name", value: "one-value"),
            .init(name: "two-name", value: "two-value"),
        ]
        
        let adaptor = ParametersAdaptor(items: items)
        
        let cleanUrlRequest = URLRequest.mock
        let adaptedCleanUrlRequest = try await adaptor.adapt(cleanUrlRequest, for: .shared)
        XCTAssertEqual(
            adaptedCleanUrlRequest.url,
            .mock.appending(queryItems: items)
        )
        
        let dirtyUrlRequest = URLRequest(url: .mock.appending(queryItems: []))
        let adaptedDirtyUrlRequest = try await adaptor.adapt(dirtyUrlRequest, for: .shared)
        XCTAssertEqual(
            adaptedDirtyUrlRequest.url,
            .mock.appending(queryItems: items)
        )
        
        let existingParametersUrlRequest = URLRequest(url: .mock.appending(queryItems: [
            .init(name: "two-name", value: "original-two-value"),
            .init(name: "other-name", value: "other-value"),
        ]))
        let adaptedExistingParametersUrlRequest = try await adaptor.adapt(existingParametersUrlRequest, for: .shared)
        XCTAssertEqual(
            adaptedExistingParametersUrlRequest.url,
            .mock.appending(queryItems: [
                .init(name: "two-name", value: "original-two-value"),
                .init(name: "other-name", value: "other-value"),
            ] + items)
        )
    }
    
    func test_request_adaptorConvenience_isAddedToRequestAdaptors() async throws {
        let client = HTTPClient()
        let request = client.request(for: .get, to: .mock, expecting: String.self)
        
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
