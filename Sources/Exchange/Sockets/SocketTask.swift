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

// MARK: - SocketTask

/// An object that provides the interactions necessary for working with socket tasks.
public struct SocketTask {
    var resume: () -> Void
    var receive: () async throws -> URLSessionWebSocketTask.Message
    var send: (URLSessionWebSocketTask.Message) async throws -> Void
    var cancel: (URLSessionWebSocketTask.CloseCode, Data?) -> Void
    var ping: () async throws -> Void
    var closeCode: () -> URLSessionWebSocketTask.CloseCode
    var closeReason: () -> Data?
    var state: () -> URLSessionWebSocketTask.State
    var error: () -> Error?
}

// MARK: - SocketTask + Initializers

extension SocketTask {
    /// Creates a ``SocketTask`` from the provided `URLSessionWebSocketTask`
    init(task: URLSessionWebSocketTask) {
        self.init(
            resume: task.resume,
            receive: task.receive,
            send: task.send,
            cancel: task.cancel(with:reason:),
            ping: {
                try await withCheckedThrowingContinuation { continuation in
                    task.sendPing { error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                }
            },
            closeCode: { task.closeCode },
            closeReason: { task.closeReason },
            state: { task.state },
            error: { task.error }
        )
    }
}

