//
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

class SocketTests: XCTestCase {
    
    // MARK: Tests
    
    func test_socket_receivesClosureEvent_whenServerCancelsConnection() async throws {
        let server = SocketServer()
        server.cancel(code: .normalClosure, reason: Data())
        
        let receivedEvents = await server.socket.stream().reduce(into: []) { $0.append($1) }
        XCTAssertEqual(receivedEvents.count, 1)
        guard case .closure(let code, let reason, let error) = receivedEvents[0] else {
            XCTFail("Expected a closure event.")
            return
        }
        
        XCTAssertTrue(code == .normalClosure)
        XCTAssertTrue(reason == Data())
        XCTAssertTrue(error as? SocketServer.Error == .serverCalledCancel)
    }
    
    func test_socket_receivesClosureEvent_whenClientCancelsConnection() async throws {
        let server = SocketServer()
        server.socket.cancel(code: .normalClosure, reason: Data())
        
        let receivedEvents = await server.socket.stream().reduce(into: []) { $0.append($1) }
        XCTAssertEqual(receivedEvents.count, 1)
        guard case .closure(let code, let reason, let error) = receivedEvents[0] else {
            XCTFail("Expected a closure event.")
            return
        }
        
        XCTAssertTrue(code == .normalClosure)
        XCTAssertTrue(reason == Data())
        XCTAssertTrue(error as? SocketServer.Error == .clientCalledCancel)
    }
    
    func test_socket_receivesMessageEvent_whenServerSendsMessage() async throws {
        let server = SocketServer()
        server.send(message: .string("Message #1"))
        server.send(message: .string("Message #2"))
        server.cancel(code: .normalClosure, reason: nil)
        
        var receivedMessages = [String]()
        for await event in server.socket.stream() {
            guard case .message(.string(let message)) = event else {
                continue
            }
            
            receivedMessages.append(message)
        }
        
        XCTAssertEqual(receivedMessages, ["Message #1", "Message #2"])
    }
    
    func test_server_receivesMessageEvent_whenSocketSendsMessage() async throws {
        let server = SocketServer()
        try await server.socket.send(message: .string("Message #1"))
        try await server.socket.send(message: .string("Message #2"))
        server.socket.cancel(code: .normalClosure, reason: nil)
        
        let receivedSocketEvents = await server.socket.stream().reduce(into: []) { $0.append($1) }
        XCTAssertEqual(receivedSocketEvents.count, 1)
        
        let receivedServerMessages = await server.stream().reduce(into: [String]()) {
            guard case .string(let message) = $1 else {
                return
            }
            
            $0.append(message)
        }
        
        XCTAssertEqual(receivedServerMessages, ["Message #1", "Message #2"])
    }
}
