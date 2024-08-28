//
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

@testable import StateBinding
import ConcurrencyExtras
import SwiftUI
import XCTest

@MainActor
class StateBindingTests: XCTestCase {
    func test_stateBinding_whenProvidedExternalBinding_doesUseExternalBinding() async {
        let getterExpectation = expectation(description: "Expected binding getter.")
        getterExpectation.expectedFulfillmentCount = 2

        let setterExpectation = expectation(description: "Expected binding setter.")

        let count = LockIsolated(0)
        let binding = Binding(
            get: {
                getterExpectation.fulfill()
                return count.value
            },
            set: {
                setterExpectation.fulfill()
                count.setValue($0)
            }
        )
        @StateBinding var counter = 5
        _counter.externalBinding = binding
        binding.wrappedValue = 10
        XCTAssertEqual(counter, 10)
        await fulfillment(of: [setterExpectation, getterExpectation], enforceOrder: true)
    }
}
