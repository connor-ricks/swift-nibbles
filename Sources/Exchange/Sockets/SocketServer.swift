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

import Foundation
import XCTest

// MARK: - SocketServer

/// A ``SocketServer`` can be used to mock an interaction with a service.
/// This can be useful for mocking data within unit tests and previews.
///
/// Interacting with the server from the client's perspective is as easy as utilizing the ``Socket`` provided by the server
/// using the ``socket`` property. You can interact with and treat it as any ``Socket`` you created yourself.
///
/// Sending messages as the server can be performed using the ``send(message:)`` method. Messages are
/// sent to the socket's stream.
///
/// Cancelling the connection as the server is handled by calling ``cancel(code:reason:)``. This will send a
/// closure event to the socket's stream.
///
/// If you are interested in observing what events are received by the server, you can listen using the ``stream()`` method.
public class SocketServer {
    
    // MARK: Error
    
    public enum Error: Swift.Error {
        case clientCalledCancel
        case serverCalledCancel
    }
    
    // MARK: Properties
    
    /// A stream and continuation of events sent to the socket.
    private let (socketStream, socketContinuation) = AsyncStream.makeStream(of: Socket.Event.self, bufferingPolicy: .unbounded)
    
    /// A stream and continuation of messages sent to the server.
    private let (clientStream, clientContinuation) = AsyncStream.makeStream(of: URLSessionWebSocketTask.Message.self, bufferingPolicy: .unbounded)
    
    /// The socket that interacts with this server.
    public private(set) lazy var socket: Socket = {
        var state = URLSessionWebSocketTask.State.suspended
        var closeCode = URLSessionWebSocketTask.CloseCode.invalid
        var closeReason = Optional<Data>.none
        var error = Optional<Swift.Error>.none
        
        return Socket(task: .init(
            resume: { state = .running },
            receive: { [socketStream, socketContinuation, clientContinuation] in
                for await event in socketStream {
                    while state != .running { continue }
                    
                    switch event {
                    case .message(let message):
                        return message
                    case .closure(let code, let reason, let err):
                        state = .completed
                        closeCode = code
                        closeReason = reason
                        error = err
                        socketContinuation.finish()
                        clientContinuation.finish()
                        throw err
                    }
                }
                
                preconditionFailure("""
                The serverContinuation was finished without an explicit call to the server's cancel method.
                This is a programmer error. Do not explicitly end the server's stream. Instead, call cancel(code:reason:)
                """)
            },
            send: { [weak self] message in
                self?.clientContinuation.yield(message)
            },
            cancel: { [weak self] code, reason in
                self?.socketContinuation.yield(.closure(
                    code: code,
                    reason: reason,
                    error: Error.clientCalledCancel
                ))
            },
            ping: { },
            closeCode: { closeCode },
            closeReason: { closeReason },
            state: { state },
            error: { error }
        ))
    }()
    
    // MARK: Initializers
    
    public init() {}
    
    // MARK: Methods
    
    /// A stream of messages sent by the client.
    public func stream() -> AsyncStream<URLSessionWebSocketTask.Message> {
        clientStream
    }
    
    /// Sends a message to the client.
    ///
    /// - Parameter message: The message that should be sent.
    public func send(message: URLSessionWebSocketTask.Message) {
        socketContinuation.yield(.message(message))
    }
    
    /// Closes the connection with the client.
    ///
    /// - Parameters:
    ///   - code: A code representing the cause of the closure.
    ///   - reason: An optional reason that provides context as to why the connection was closed.
    public func cancel(code: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        socketContinuation.yield(.closure(
            code: code,
            reason: reason,
            error: Error.serverCalledCancel
        ))
    }
}
