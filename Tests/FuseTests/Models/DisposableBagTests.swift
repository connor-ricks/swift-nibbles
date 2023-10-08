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

class DisposableBagTests: XCTestCase {
    
    // MARK: MockCancellable
    struct MockCancellable: Cancellable {
        let id: Int
        func cancel() {}
    }
    
    // MARK: Tests
    
    func test_disposableBag_whenStoringAndDisposingCancellable_doesUpdateCancellableSet() {
        let bag = DisposableBag()
        let cancellableOne = AnyCancellable(MockCancellable(id: 1))
        let cancellableTwo = AnyCancellable(MockCancellable(id: 2))
        
        bag.store(cancellableOne)
        XCTAssertTrue(bag.cancellables == [cancellableOne])
        
        bag.store(cancellableTwo)
        XCTAssertTrue(bag.cancellables == [cancellableOne, cancellableTwo])
        
        bag.dispose(cancellableTwo)
        XCTAssertTrue(bag.cancellables == [cancellableOne])
        
        bag.dispose(cancellableOne)
        XCTAssertTrue(bag.cancellables == [])
    }
    
    func test_disposableBag_whenEmptying_doesRemoveAllCancellables() {
        let bag = DisposableBag()
        let cancellableOne = AnyCancellable(MockCancellable(id: 1))
        let cancellableTwo = AnyCancellable(MockCancellable(id: 2))
        
        bag.store(cancellableOne)
        bag.store(cancellableTwo)
        
        bag.empty()
        XCTAssertTrue(bag.cancellables == [])
    }
    
    func test_disposableBag_whenDisposingCancellableNotInBag_doesNotAlterBag() {
        let bag = DisposableBag()
        let cancellableOne = AnyCancellable(MockCancellable(id: 1))
        let cancellableTwo = AnyCancellable(MockCancellable(id: 2))
        let cancellableThree = AnyCancellable(MockCancellable(id: 3))
        
        bag.store(cancellableOne)
        bag.store(cancellableTwo)
        
        bag.dispose(cancellableThree)
        XCTAssertTrue(bag.cancellables == [cancellableOne, cancellableTwo])
    }
}
