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
import Combine
import XCTest

class BuffableAsyncThrowingPublisherTests: XCTestCase {
    
    // MARK: MockError
    
    struct MockError: Error {}
    
    // MARK: Observer
    
    class Observer {
        var sent = [Int]()
        var received = [Int]()
    }
    
    // MARK: Tests
    
    func test_buffableAsyncThrowingPublisher_withUnboundedPolicy_publishesEveryValue() async throws {
        let observer = Observer()
        let subject = PassthroughSubject<Int, MockError>()
        let values = subject.values(bufferingPolicy: .unbounded)
        
        // Buffer the stream
        for i in 0..<99 {
            subject.send(i)
            observer.sent.append(i)
        }
        subject.send(completion: .finished)
        
        // Iterate over the stream, collecting all buffered values.
        for try await num in values {
            observer.received.append(num)
        }
        
        // Compare received vs sent
        XCTAssertEqual(observer.received, observer.sent)
    }
    
    func test_buffableAsyncThrowingPublisher_withBufferingNewestPolicy_publishesEveryValue() async throws {
        let observer = Observer()
        let subject = PassthroughSubject<Int, MockError>()
        let values = subject.values(bufferingPolicy: .bufferingNewest(5))
        
        // Buffer the stream
        for i in 0..<99 {
            subject.send(i)
            observer.sent.append(i)
        }
        subject.send(completion: .finished)
        
        // Iterate over the stream, collecting all buffered values.
        for try await num in values {
            observer.received.append(num)
        }
        
        // Compare received vs sent
        XCTAssertEqual(observer.received, observer.sent.suffix(5))
    }
    
    func test_buffableAsyncThrowingPublisher_withBufferingOldestPolicy_publishesEveryValue() async throws {
        let observer = Observer()
        let subject = PassthroughSubject<Int, MockError>()
        let values = subject.values(bufferingPolicy: .bufferingOldest(5))
        
        // Buffer the stream
        for i in 0..<99 {
            subject.send(i)
            observer.sent.append(i)
        }
        subject.send(completion: .finished)
        
        // Iterate over the stream, collecting all buffered values.
        for try await num in values {
            observer.received.append(num)
        }
        
        // Compare received vs sent
        XCTAssertEqual(observer.received, Array(observer.sent.prefix(5)))
    }
    
    func test_buffableAsyncThrowingPublisher_whenSubjectFinished_stopsPublishingValues() async throws {
        let observer = Observer()
        let subject = PassthroughSubject<Int, MockError>()
        let values = subject.values(bufferingPolicy: .unbounded)
        
        // Buffer the stream
        for i in 0..<5 {
            subject.send(i)
            observer.sent.append(i)
        }
        
        subject.send(completion: .finished)
        
        // Buffer the stream
        for i in 0..<5 {
            subject.send(i)
            observer.sent.append(i)
        }
        
        // Iterate over the stream, collecting all buffered values.
        for try await num in values {
            observer.received.append(num)
        }
        
        // Compare received vs sent
        XCTAssertEqual(observer.received, Array(observer.sent.prefix(5)))
    }
    
    func test_buffableAsyncThrowingPublisher_whenPublisherIsCancelled_stopsPublishingValues() async throws {
        let observer = Observer()
        let subject = PassthroughSubject<Int, MockError>()
        let values = subject.values(bufferingPolicy: .unbounded)
        
        // Buffer the stream
        for i in 0..<5 {
            subject.send(i)
            observer.sent.append(i)
        }
        values.cancel()
        
        // Buffer the stream
        for i in 0..<5 {
            subject.send(i)
            observer.sent.append(i)
        }
        
        // Iterate over the stream, collecting all buffered values.
        for try await num in values {
            observer.received.append(num)
        }
        
        // Compare received vs sent
        XCTAssertEqual(observer.received, Array(observer.sent.prefix(5)))
    }
    
    func test_buffableAsyncThrowingPublisher_whenIteratorIsBroken_canContinueIterating() async throws {
        let observer = Observer()
        let subject = PassthroughSubject<Int, MockError>()
        let values = subject.values(bufferingPolicy: .unbounded)
        
        // Buffer the stream
        for i in 0..<99 {
            subject.send(i)
            observer.sent.append(i)
        }
        
        subject.send(completion: .finished)
        
        // Iterate over the stream, collecting buffered values.
        for try await num in values {
            observer.received.append(num)
            guard num < 49 else { break }
        }
        
        // Resume iterating over the stream, collecting the remaining buffered values.
        for try await num in values {
            observer.received.append(num)
        }
        
        // Compare received vs sent
        XCTAssertEqual(observer.received, observer.sent)
    }
    
    func test_buffableAsyncThrowingPublisher_whenErrorIsSent_errorIsThrownAndStopsPublishingValues() async throws {
        let observer = Observer()
        let subject = PassthroughSubject<Int, MockError>()
        let values = subject.values(bufferingPolicy: .unbounded)
        
        // Buffer the stream
        for i in 0..<5 {
            subject.send(i)
            observer.sent.append(i)
        }
        
        // Send error and end stream.
        subject.send(completion: .failure(MockError()))
        
        // Buffer the stream
        for i in 0..<5 {
            subject.send(i)
            observer.sent.append(i)
        }
        
        // Iterate over the stream, collecting all buffered values.
        do {
            for try await num in values {
                observer.received.append(num)
            }
            
            XCTFail("Expected MockError to be thrown!")
        } catch {
            XCTAssertTrue(error is MockError)
        }
        
        // Compare received vs sent
        XCTAssertEqual(observer.received, Array(observer.sent.prefix(5)))
    }
}
