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

@testable import HTTPNetworking
import XCTest

class ZipRetrierTests: XCTestCase {
    func test_zipRetrier_withRetriers_containsRetriersInOrder() {
        struct TestRetrier: HTTPRequestRetrier, Equatable {
            let id: Int
            func retry(
                _ request: URLRequest,
                for session: URLSession,
                with response: HTTPURLResponse?,
                dueTo error: Error,
                previousAttempts: Int
            ) async -> HTTPNetworking.RetryDecision {
                .concede
            }
        }
        
        let one = TestRetrier(id: 1)
        let two = TestRetrier(id: 2)
        let three = TestRetrier(id: 3)
        let expectedRetriers = [one, two, three]
        
        let zipRetrier = ZipRetrier(expectedRetriers)
        XCTAssertEqual(zipRetrier.retriers as? [TestRetrier], expectedRetriers)
        
        let variadicZip = ZipRetrier(one, two, three)
        XCTAssertEqual(variadicZip.retriers as? [TestRetrier], expectedRetriers)
    }
    
    func test_zipRetrier_whenCancelled_stopsIteratingThroughRetriers() async {
        var task: Task<Void, Error>?
        let retrierOneExpectation = expectation(description: "Expected retrier one to be executed.")
        let retrierTwoExpectation = expectation(description: "Expected retrier two to be executed.")
        
        let zipRetrier = ZipRetrier([
            Retrier { _, _, _, _, _ in
                retrierOneExpectation.fulfill()
                return .concede
            },
            Retrier { _, _, _, _, _ in
                retrierTwoExpectation.fulfill()
                task?.cancel()
                return .concede
            },
            Retrier { _, _, _, _, _ in
                XCTFail("Expected task to be cancelled and third retrier to be skipped.")
                return .concede
            }
        ])
        
        task = Task {
            do {
                _ = try await zipRetrier.retry(
                    .mock,
                    for: .shared,
                    with: nil,
                    dueTo: URLError(.cannotParseResponse),
                    previousAttempts: 0
                )
            } catch {
                XCTAssertTrue(error is CancellationError)
            }
        }
        
        await fulfillment(of: [retrierOneExpectation, retrierTwoExpectation], enforceOrder: true)
    }
    
    func test_zipRetrier_retrierConvenience_isAddedToRequestRetriers() async throws {
        let client = HTTPClient()
        let request = client.request(for: .get, to: .mock, expecting: String.self)
        let expectationOne = expectation(description: "Expected retrier one to be called.")
        let expectationTwo = expectation(description: "Expected retrier two to be called.")
        request.retry(zipping: [
            Retrier { _, _, _, _, _ in
                expectationOne.fulfill()
                return .concede
            },
            Retrier { _, _, _, _, _ in
                expectationTwo.fulfill()
                return .concede
            },
        ])
        
        _ = try await request.retriers.first?.retry(
            request.request,
            for: .shared,
            with: nil,
            dueTo: URLError(.cannotParseResponse),
            previousAttempts: 0
        )
        
        await fulfillment(of: [expectationOne, expectationTwo], enforceOrder: true)
    }
}
