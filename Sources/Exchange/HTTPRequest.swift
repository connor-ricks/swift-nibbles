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

/// An ``HTTPRequest`` contains all the information necessary to send a request over the network.
///
/// Create an ``HTTPRequest`` by creating an ``HTTPClient`` and
/// calling ``HTTPClient/request(for:to:expecting:)`` or ``HTTPClient/request(for:to:with:expecting:)``
/// with the desired configuration.
///
/// To send an ``HTTPRequest`` call ``run()``. This will perform the network request ant return the expected response type.
///
/// Each ``HTTPRequest`` is setup with concurrency in mind. In-flight requests are periodically checked for `Task` cancellation and will approprietly stop
/// when their parent task is cancelled.
///
/// > Tip: You can adapt the `URLRequest`, before it gets sent out, by calling methods like ``adapt(_:)`` or ``adapt(with:)``.
/// By providing an ``AdaptationHandler`` or any ``HTTPRequestAdaptor``, you can perform various asyncronous logic before a request gets sent
/// Typical use cases include things like adding headers to requests, or managing the lifecycle of a client's authorization status.
///
/// > Tip: You can validate the `HTTPURLResponse`, before it gets deocded, by calling  methods like ``validate(_:)`` or ``validate(with:)``.
/// By providing a ``ValidationHandler`` or any ``HTTPResponseValidator``, you can perform various validations before a response is decoded.
/// Typical use cases include things like validating the status code or headers of a request.
///
/// > Tip: You can retry the ``HTTPRequest`` if it fails by calling retry methods like ``retry(_:)`` or ``retry(with:)``.
/// By providing a ``RetryHandler`` or any ``HTTPRequestRetrier``, you can determine if a request should be retried if it fails.
/// Typical use cases include retrying requests a given number of times in the event of poor network connectivity.
public class HTTPRequest<Value: Decodable> {
    
    // MARK: Properties
    
    /// The underlying request to be dispatched.
    let request: URLRequest
    
    /// A customized decoder for response parsing.
    let decoder: JSONDecoder
    
    /// The `HTTPDispatcher` that dispatches requests.
    let dispatcher: HTTPDispatcher
    
    /// A collection of adaptors that adapt each request.
    private(set) var adaptors: [any HTTPRequestAdaptor]
    
    /// A collection of retriers that handle retrying upon request failure.
    private(set) var retriers: [any HTTPRequestRetrier]
    
    /// A collection of validators that validate each response.
    private(set) var validators: [any HTTPResponseValidator]
    
    // MARK: Initailizers
    
    init(
        request: URLRequest,
        decoder: JSONDecoder,
        dispatcher: HTTPDispatcher,
        adaptors: [any HTTPRequestAdaptor],
        retriers: [any HTTPRequestRetrier],
        validators: [any HTTPResponseValidator]
    ) {
        self.request = request
        self.decoder = decoder
        self.dispatcher = dispatcher
        self.adaptors = adaptors
        self.retriers = retriers
        self.validators = validators
    }
    
    // MARK: Execution
    
    /// Dispatches the request, returning the request's expected `Value`.
    public func run() async throws -> Value {
        try await execute(previousAttempts: 0)
    }
    
    /// Executes the request to the dispatcher.
    private func execute(previousAttempts: Int) async throws -> Value {
        var request = self.request
        var response: HTTPURLResponse?
        
        do {
            
            try Task.checkCancellation()
            
            // Create the adapted request.
            request = try await ZipAdaptor(adaptors).adapt(request, for: dispatcher.session)
            
            try Task.checkCancellation()
            
            // Dispatch the request and wait for a response.
            let reply = try await dispatcher.data(for: request)
            response = reply.response
            
            try Task.checkCancellation()
            
            // Validate the response.
            try await ZipValidator(validators)
                .validate(reply.response, for: request, with: reply.data)
                .get()
            
            try Task.checkCancellation()
            
            // Convert data to the expected type
            return try decoder.decode(Value.self, from: reply.data)
        } catch {
            let previousAttempts = previousAttempts + 1
            let strategy = try await ZipRetrier(retriers).retry(
                request,
                for: dispatcher.session,
                with: response,
                dueTo: error,
                previousAttempts: previousAttempts
            )
            
            switch strategy {
            case .concede:
                throw error
            case .retryAfterDelay(let delay):
                try await Task.sleep(for: delay)
                fallthrough
            case .retry:
                return try await execute(previousAttempts: previousAttempts)
            }
        }
    }
    
    // MARK: Adapt
    
    /// Applies the provided adaptor to the request.
    @discardableResult
    public func adapt<A>(with adaptor: A) -> Self where A: HTTPRequestAdaptor {
        adaptors.append(adaptor)
        return self
    }
    
    // MARK: Retry
    
    /// Applies the provided retrier to the request's retry strategy.
    @discardableResult
    public func retry<R>(with retrier: R) -> Self where R: HTTPRequestRetrier {
        retriers.append(retrier)
        return self
    }
    
    // MARK: Validate
    
    /// Applies the provided validator to the request's response validation.
    @discardableResult
    public func validate<V>(with validator: V) -> Self where V: HTTPResponseValidator {
        validators.append(validator)
        return self
    }
}
