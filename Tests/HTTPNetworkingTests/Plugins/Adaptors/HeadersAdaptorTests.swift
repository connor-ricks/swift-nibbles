@testable import HTTPNetworking
import XCTest

class HeadersAdaptorTests: XCTestCase {
    func test_headersAdaptor_withUseOlderValueStrategy_returnsExpectedParameters() async throws {
        let headerAdaptorOne = HeadersAdaptor(headers: [
            "HEADER-ONE": "VALUE-ONE-OLD",
            "HEADER-TWO": "VALUE-TWO-OLD",
        ], strategy: .useOlderValue)
        
        let headerAdaptorTwo = HeadersAdaptor(headers: [
            "HEADER-TWO": "VALUE-TWO-NEW",
            "HEADER-THREE": "VALUE-THREE-NEW",
        ], strategy: .useOlderValue)
        
        let adaptor = ZipAdaptor([headerAdaptorOne, headerAdaptorTwo])
        let request = try await adaptor.adapt(URLRequest(url: .mock), for: .shared)
        
        XCTAssertEqual(request.allHTTPHeaderFields, [
            "HEADER-ONE": "VALUE-ONE-OLD",
            "HEADER-TWO": "VALUE-TWO-OLD",
            "HEADER-THREE": "VALUE-THREE-NEW",
        ])
    }
    
    func test_headersAdaptor_withUseNewerValueStrategy_returnsExpectedParameters() async throws {
        let headerAdaptorOne = HeadersAdaptor(headers: [
            "HEADER-ONE": "VALUE-ONE-OLD",
            "HEADER-TWO": "VALUE-TWO-OLD",
        ], strategy: .useNewerValue)
        
        let headerAdaptorTwo = HeadersAdaptor(headers: [
            "HEADER-TWO": "VALUE-TWO-NEW",
            "HEADER-THREE": "VALUE-THREE-NEW",
        ], strategy: .useNewerValue)
        
        let adaptor = ZipAdaptor([headerAdaptorOne, headerAdaptorTwo])
        let request = try await adaptor.adapt(URLRequest(url: .mock), for: .shared)
        
        XCTAssertEqual(request.allHTTPHeaderFields, [
            "HEADER-ONE": "VALUE-ONE-OLD",
            "HEADER-TWO": "VALUE-TWO-NEW",
            "HEADER-THREE": "VALUE-THREE-NEW",
        ])
    }
    
    func test_headersAdaptor_withUseBothValuesStrategy_returnsExpectedParameters() async throws {
        let headerAdaptorOne = HeadersAdaptor(headers: [
            "HEADER-ONE": "VALUE-ONE-OLD",
            "HEADER-TWO": "VALUE-TWO-OLD",
        ], strategy: .useBothValues)
        
        let headerAdaptorTwo = HeadersAdaptor(headers: [
            "HEADER-TWO": "VALUE-TWO-NEW",
            "HEADER-THREE": "VALUE-THREE-NEW",
        ], strategy: .useBothValues)
        
        let adaptor = ZipAdaptor([headerAdaptorOne, headerAdaptorTwo])
        let request = try await adaptor.adapt(URLRequest(url: .mock), for: .shared)
        
        XCTAssertEqual(request.allHTTPHeaderFields, [
            "HEADER-ONE": "VALUE-ONE-OLD",
            "HEADER-TWO": "VALUE-TWO-OLD,VALUE-TWO-NEW",
            "HEADER-THREE": "VALUE-THREE-NEW",
        ])
    }
    
    func test_headersAdaptor_withUseCustomStrategy_callsHandlerAndReturnsExpectedParameters() async throws {
        let expectation = expectation(description: "Expected handler to be called")
        let headerAdaptorOne = HeadersAdaptor(headers: [
            "HEADER-ONE": "VALUE-ONE-OLD",
            "HEADER-TWO": "VALUE-TWO-OLD",
        ], strategy: .useBothValues)
        
        let headerAdaptorTwo = HeadersAdaptor(headers: [
            "HEADER-TWO": "VALUE-TWO-NEW",
            "HEADER-THREE": "VALUE-THREE-NEW",
        ], strategy: .custom({ _, _, newValue in
            expectation.fulfill()
            return newValue
        }))
        
        let adaptor = ZipAdaptor([headerAdaptorOne, headerAdaptorTwo])
        let request = try await adaptor.adapt(URLRequest(url: .mock), for: .shared)
        
        XCTAssertEqual(request.allHTTPHeaderFields, [
            "HEADER-ONE": "VALUE-ONE-OLD",
            "HEADER-TWO": "VALUE-TWO-NEW",
            "HEADER-THREE": "VALUE-THREE-NEW",
        ])
        
        await fulfillment(of: [expectation])
    }
    
    func test_request_adaptorConvenience_isAddedToRequestAdaptors() async throws {
        let client = HTTPClient()
        let request = client.request(for: .get, to: .mock, expecting: String.self)
        
        let headers: [String: String] = [
            "HEADER-ONE": "VALUE-ONE",
            "HEADER-TWO": "VALUE-TWO",
        ]
        
        request.adapt(headers: headers)
        
        guard let adaptor = request.adaptors.first as? HeadersAdaptor else {
            XCTFail("Expected request to container HeadersAdaptor.")
            return
        }
        
        XCTAssertEqual(adaptor.headers, headers)
    }
}
