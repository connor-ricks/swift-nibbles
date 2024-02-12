// MIT License
//
// Copyright (c) 2024 Connor Ricks
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

import ConcurrencyExtras
@testable import SharedState
import XCTest

class SharedStateTests: XCTestCase {
    func test_sharedState_mutate_doesUpdateAndNotify() async throws {
        struct Container: Equatable { var num: Int }
        let onChangeExpectation = expectation(description: "Expected onChange to be called.")
        let publisherExpectation = expectation(description: "Expected publisher to be triggered.")
        let publisherKeyPathExpectation = expectation(description: "Expected publisher keypath to be triggered.")
        let streamExpectation = expectation(description: "Expected stream to be triggered.")
        let streamKeyPathExpectation = expectation(description: "Expected stream keypath to be triggered.")
        
        await withMainSerialExecutor {
            let sharedState = SharedState(Container(num: 10), onChange: { old, new in
                XCTAssertEqual(old.num, 10)
                XCTAssertEqual(new.num, 5)
                onChangeExpectation.fulfill()
            })
            
            // Publisher Subscription
            let cancellable = sharedState.publisher.sink { container in
                XCTAssertEqual(container.num, 5)
                publisherExpectation.fulfill()
            }
            
            // Publisher Keypath Subscription
            let cancellableKeyPath = sharedState[publisher: \.num].sink { num in
                XCTAssertEqual(num, 5)
                publisherKeyPathExpectation.fulfill()
            }
            
            // Streaming Subscription
            Task {
                for await container in sharedState.stream(bufferingPolicy: .unbounded) {
                    XCTAssertEqual(container.num, 5)
                    streamExpectation.fulfill()
                    return
                }
            }
            
            // Streaming Keypath Subscription
            Task {
                for await num in sharedState[stream: \.num] {
                    XCTAssertEqual(num, 5)
                    streamKeyPathExpectation.fulfill()
                    return
                }
            }
            
            XCTAssertEqual(sharedState(), .init(num: 10))
            XCTAssertEqual(sharedState.num, 10)
            XCTAssertEqual(sharedState[keyPath: \.num], 10)
            
            await sharedState.mutate {
                await Task.yield()
                $0.num = 5
            }
            
            XCTAssertEqual(sharedState(), .init(num: 5))
            XCTAssertEqual(sharedState.num, 5)
            XCTAssertEqual(sharedState[keyPath: \.num], 5)
            
            await fulfillment(of: [
                onChangeExpectation,
                publisherExpectation,
                publisherKeyPathExpectation,
                streamExpectation,
                streamKeyPathExpectation,
            ])
        }
    }
    
}
