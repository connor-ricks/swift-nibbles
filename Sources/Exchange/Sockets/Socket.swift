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

// MARK: - Socket

/// `Socket` creates and manages a websocket over the network.
///
/// A `Socket` is created by providing the `URL` of the service that you which to connect to.
/// Once a socket is initialized, a `URLSessionWebSocketTask` is created and resumed in order to open a connection
/// with the service.
///
/// Sending information over the socket is as easy as calling ``send(message:)`` with the data you would
/// like to send.
///
/// Receiving information over the socket can be accomplished using the ``stream()`` function.
/// Doing so will return a stream of ``Event`` objects that provide the messages received from the service,
/// as well as any closure events indicating the end of the connection.
///
/// If you need to ping the service, there is a ``ping()`` method that allows you to validate the connection is still functional.
///
/// When you are finished with the connection, you can cancel the socket's connection by calling ``cancel(code:reason:)``
public struct Socket {
    
    public typealias Stream = AsyncStream<Event>
    
    // MARK: Event
    
    /// An event that is received when listening to a socket's stream.
    public enum Event {
        case message(URLSessionWebSocketTask.Message)
        case closure(code: URLSessionWebSocketTask.CloseCode, reason: Data?, error: Error)
    }
    
    // MARK: Properties
    
    /// The task that powers the socket communication.
    private let task: SocketTask
    
    // MARK: Initializers
    
    /// Creates a socket from the provided `url` using the specified `protocols` and `configuration`.
    /// - Parameters:
    ///   - url: The url of the websocket connection.
    ///   - protocols: Protocols that should be specified with the
    ///   - configuration: The configuration of the `URLSession` that will power the socket.
    public init(url: URL, protocols: [String] = [], configuration: URLSessionConfiguration = .default) {
        let session = URLSession(configuration: configuration)
        self.task = SocketTask(task: session.webSocketTask(with: url, protocols: protocols))
        task.resume()
    }
    
    /// Creates a socket from the provided task.
    /// 
    /// This initializer is used internally in order to create mock sockets powered by a ``SocketServer``.
    init(task: SocketTask) {
        self.task = task
        task.resume()
    }
    
    // MARK: Actions
    
    /// A stream of events received by the socket and the server it is communicating with.
    public func stream() -> Stream {
        return Stream { continuation in
            Task {
                while task.closeCode() == .invalid {
                    do {
                        let message = try await task.receive()
                        continuation.yield(.message(message))
                    } catch {
                        continuation.yield(.closure(
                            code: task.closeCode(),
                            reason: task.closeReason(),
                            error: error
                        ))
                        break
                    }
                }
                
                continuation.finish()
            }
        }
    }
    
    /// Sends a message to the server.
    ///
    /// - Parameter message: The message that should be sent.
    public func send(message: URLSessionWebSocketTask.Message) async throws {
        try await task.send(message)
    }
    
    /// Closes the connection with the server.
    ///
    /// - Parameters:
    ///   - code: A code representing the cause of the closure.
    ///   - reason: An optional reason that provides context as to why the connection was closed.
    public func cancel(code: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        task.cancel(code, reason)
    }
    
    /// Sends a ping to the websocket.
    public func ping() async throws {
        try await task.ping()
    }
}
