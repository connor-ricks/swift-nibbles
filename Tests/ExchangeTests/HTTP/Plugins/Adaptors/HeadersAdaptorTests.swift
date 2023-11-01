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
        let request = try await adaptor.adapt(.mock, for: .shared)
        
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
        let request = try await adaptor.adapt(.mock, for: .shared)
        
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
        let request = try await adaptor.adapt(.mock, for: .shared)
        
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
        let request = try await adaptor.adapt(.mock, for: .shared)
        
        XCTAssertEqual(request.allHTTPHeaderFields, [
            "HEADER-ONE": "VALUE-ONE-OLD",
            "HEADER-TWO": "VALUE-TWO-NEW",
            "HEADER-THREE": "VALUE-THREE-NEW",
        ])
        
        await fulfillment(of: [expectation])
    }
    
    func test_request_adaptorConvenience_isAddedToRequestAdaptors() async throws {
        let client = HTTPClient()
        let headers: [String: String] = [
            "HEADER-ONE": "VALUE-ONE",
            "HEADER-TWO": "VALUE-TWO",
        ]
        
        let request = client.request(for: .get, to: .mock, expecting: String.self)
            .adapt(headers: headers)
        
        guard let adaptor = request.adaptors.first as? HeadersAdaptor else {
            XCTFail("Expected request to container HeadersAdaptor.")
            return
        }
        
        XCTAssertEqual(adaptor.headers, headers)
    }
}
