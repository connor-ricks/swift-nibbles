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
