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

class AdaptorTests: XCTestCase {
    func test_adaptor_withProvidedHandler_callsHandlerOnAdaptation() async throws {
        let client = HTTPClient()
        let request = client.request(for: .get, to: .mock, expecting: String.self)
        let expectation = expectation(description: "Expected handler to be called.")
   
        let adaptor = Adaptor { request, _ in
            expectation.fulfill()
            return request
        }
    
        _ = try await adaptor.adapt(request.request, for: .shared)
        await fulfillment(of: [expectation])
    }
    
    func test_request_adaptorConvenience_isAddedToRequestAdaptors() async throws {
        let client = HTTPClient()
        let expectation = expectation(description: "Expected adaptor to be called.")
        let request = client.request(for: .get, to: .mock, expecting: String.self)
            .adapt { request, _ in
            expectation.fulfill()
            return request
        }
        
        _ = try await request.adaptors.first?.adapt(request.request, for: client.dispatcher.session)
        
        await fulfillment(of: [expectation])
    }
}
