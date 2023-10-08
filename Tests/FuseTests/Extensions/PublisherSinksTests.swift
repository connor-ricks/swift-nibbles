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

@testable import Fuse
import XCTest
import Combine

class PublisherSinksTests: XCTestCase {

    private struct MockError: Error {}

    // MARK: Constants

    private enum Constants {
        static let waitTimeout: TimeInterval = 2.0
    }

    // MARK: Properties

    var cancellable: AnyCancellable?

    // MARK: Sink Tests

    func test_synchronousSink_doesComplete_whenValuesFinishedPublishing() {
        /// Setup expectations
        let valueExpectation = createReceiveValueExpectation(count: 3)
        let completionExpectation = expectation(description: "Expected publisher to complete.")

        /// Perform test
        cancellable = [1, 2, 3].publisher.sink(receiveValue: { value in
            valueExpectation.fulfill()
        }, receiveCompletion: {
            completionExpectation.fulfill()
        })

        wait(for: [
            valueExpectation,
            completionExpectation
        ], timeout: Constants.waitTimeout, enforceOrder: true)
    }

    func test_asynchronousSink_doesComplete_whenValuesFinishedPublishing() {
        /// Setup expectations
        let valueExpectation = createReceiveValueExpectation(count: 1)
        let completionExpectation = expectation(description: "Expected publisher to complete.")

        /// Perform test
        let publisher = PassthroughSubject<String, Never>()
        cancellable = publisher.sink(receiveValue: { value in
            valueExpectation.fulfill()
        }, receiveCompletion: {
            completionExpectation.fulfill()
        })

        Task {
            publisher.send("value")
            publisher.send(completion: .finished)
        }

        wait(for: [
            valueExpectation,
            completionExpectation
        ], timeout: Constants.waitTimeout, enforceOrder: true)
    }

    func test_sink_doesCancel_whenCancellableIsCancelled() {
        /// Setup expectations
        let valueExpectation = createReceiveValueExpectation(count: 1)

        /// Perform test
        let publisher = PassthroughSubject<String, Never>()
        cancellable = publisher.sink(receiveValue: { value in
            valueExpectation.fulfill()
        }, receiveCompletion: {
            XCTFail("Publisher should not have completed.")
        })

        Task {
            publisher.send("value")
            self.cancellable?.cancel()
        }

        wait(for: [valueExpectation], timeout: Constants.waitTimeout, enforceOrder: true)
    }

    func test_sink_doesError_whenErrorIsPublished() {
        /// Setup expectations
        let valueExpectation = createReceiveValueExpectation(count: 1)
        let errorExpectation = expectation(description: "Expected publisher to error.")

        /// Perform test
        let publisher = PassthroughSubject<String, MockError>()
        cancellable = publisher.sink(receiveValue: { value in
            valueExpectation.fulfill()
        }, receiveError: { error in
            errorExpectation.fulfill()
        }, receiveCompletion: {
            XCTFail("Publisher should not have completed.")
        })

        Task {
            publisher.send("value")
            publisher.send(completion: .failure(MockError()))
        }

        wait(for: [
            valueExpectation,
            errorExpectation
        ], timeout: Constants.waitTimeout, enforceOrder: true)
    }

    // MARK: DisposableBag Sinks Tests

    func test_disposableSynchronousBagSink_doesCleanup_whenValuesFinishedPublishing() {
        /// Prepare test
        let bag = DisposableBag()
        XCTAssertEqual(bag.cancellables.count, 0)

        /// Setup expectations
        let valueExpectation = createReceiveValueExpectation(count: 3)
        let completionExpectation = expectation(description: "Expected publisher to complete.")
        let emptyBagExpectation = createEmptyBagExpectation(from: bag)

        /// Perform test
        [1, 2, 3].publisher.sink(receiveValue: { value in
            valueExpectation.fulfill()
        }, receiveCompletion: {
            completionExpectation.fulfill()
        }, bag: bag)

        wait(for: [
            valueExpectation,
            completionExpectation,
            emptyBagExpectation
        ], timeout: Constants.waitTimeout, enforceOrder: true)
    }

    func test_disposableAsynchronousBagSink_doesCleanup_whenValuesFinishedPublishing() {
        /// Prepare test
        let bag = DisposableBag()
        XCTAssertEqual(bag.cancellables.count, 0)

        /// Setup expectations
        let valueExpectation = createReceiveValueExpectation(count: 1)
        let completionExpectation = expectation(description: "Expected publisher to complete.")
        let emptyBagExpectation = createEmptyBagExpectation(from: bag)

        /// Perform test
        let publisher = PassthroughSubject<String, Never>()
        publisher.sink(receiveValue: { value in
            valueExpectation.fulfill()
        }, receiveCompletion: {
            completionExpectation.fulfill()
        }, bag: bag)

        Task {
            publisher.send("value")
            publisher.send(completion: .finished)
        }

        wait(for: [
            valueExpectation,
            completionExpectation,
            emptyBagExpectation
        ], timeout: Constants.waitTimeout, enforceOrder: true)
    }

    func test_disposableBagSink_doesCleanup_whenCancellableIsCancelled() {
        /// Prepare test
        let bag = DisposableBag()
        XCTAssertEqual(bag.cancellables.count, 0)

        /// Setup expectations
        let valueExpectation = createReceiveValueExpectation(count: 1)
        let completionExpectation = expectation(description: "Publisher should complete.")
        let emptyBagExpectation = createEmptyBagExpectation(from: bag)

        /// Perform test
        let publisher = PassthroughSubject<String, Never>()
        let subscription = publisher.sink(receiveValue: { value in
            valueExpectation.fulfill()
        }, receiveCompletion: {
            completionExpectation.fulfill()
        }, bag: bag)

        Task {
            publisher.send("value")
            subscription.cancel()
        }

        wait(for: [
            valueExpectation,
            completionExpectation,
            emptyBagExpectation
        ], timeout: 2, enforceOrder: true)
    }

    func test_disposableBagSink_doesCleanup_whenErrorIsPublished() {
        /// Prepare test
        let bag = DisposableBag()
        XCTAssertEqual(bag.cancellables.count, 0)

        /// Setup expectations
        let valueExpectation = createReceiveValueExpectation(count: 1)
        let errorExpectation = expectation(description: "Expected publisher to error.")
        let emptyBagExpectation = createEmptyBagExpectation(from: bag)

        /// Perform test
        let publisher = PassthroughSubject<String, MockError>()
        publisher.sink(receiveValue: { value in
            valueExpectation.fulfill()
        }, receiveError: { error in
            errorExpectation.fulfill()
        }, receiveCompletion: {
            XCTFail("Publisher should not have completed.")
        }, bag: bag)

        Task {
            publisher.send("value")
            publisher.send(completion: .failure(MockError()))
        }

        wait(for: [
            valueExpectation,
            errorExpectation,
            emptyBagExpectation
        ], timeout: Constants.waitTimeout, enforceOrder: true)
    }
    
    func test_disposableBag_whenEmptied_doesCancelAllPublishers() {
        /// Prepare test
        let bag = DisposableBag()
        XCTAssertEqual(bag.cancellables.count, 0)

        /// Setup expectations
        let completionExpectation = expectation(description: "Expected publisher to complete.")
        let emptyBagExpectation = createEmptyBagExpectation(from: bag)

        /// Perform test
        let publisher: PassthroughSubject<String, MockError>? = .init()
        publisher?.sink(receiveValue: { value in
            XCTFail("Publisher should not have published a value.")
        }, receiveError: { error in
            XCTFail("Publisher should not have published an error.")
        }, receiveCompletion: {
            completionExpectation.fulfill()
        }, bag: bag)
        
        bag.empty()
        XCTAssertEqual(bag.cancellables.count, 0)

        wait(for: [
            completionExpectation,
            emptyBagExpectation
        ], timeout: Constants.waitTimeout, enforceOrder: true)
    }
}

// MARK: - PublisherSinksExtensionTests + Expectations

private extension PublisherSinksTests {
    func createEmptyBagExpectation(from bag: DisposableBag) -> XCTestExpectation {
        return expectation(for: NSPredicate { any, _ in
            guard let bag = any as? DisposableBag else { return false}
            return bag.cancellables.count == 0
        }, evaluatedWith: bag, handler: .none)
    }

    func createReceiveValueExpectation(count: Int = 1) -> XCTestExpectation {
        let expectation = self.expectation(description: "Expected publisher to publish \(count) values.")
        expectation.expectedFulfillmentCount = count
        return expectation
    }
}
