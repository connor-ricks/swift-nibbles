import Foundation

/// An ``HTTPRequest`` contains all the information necessary to send a request over the network.
///
/// Create an ``HTTPRequest`` by creating an ``HTTPClient`` and
/// calling ``HTTPClient/request(for:to:expecting:)`` or ``HTTPClient/request(for:to:with:expecting:)``
/// with the desired configuration.
///
/// To send an ``HTTPRequest`` call ``run()``. This will perform the network request ant return the expected response type.
///
/// You can adapt the `URLRequest`, before it gets sent out, by calling ``adapt(_:)`` or ``adapt(with:)``.
/// By providing an ``AdaptationHandler`` or ``HTTPRequestAdaptor``, you can perform various asyncronous logic before a request gets sent
/// Typical use cases include things like adding headers to requests, or managing the lifecycle of a client's authorization status.
///
/// You can validate the `HTTPURLResponse`, before it gets deocded, by calling ``validate(_:)`` or ``validate(with:)``.
/// By providing a ``ValidationHandler`` or ``HTTPResponseValidator``, you can perform various validations before a response is decoded.
/// Typical use cases include things like validating the status code or headers of a request.
///
/// You can retry the ``HTTPRequest`` if it fails by calling ``retry(_:)`` or ``retry(with:)``.
/// By providing a ``RetryHandler`` or ``HTTPRequestRetrier``, you can determine if a request should be retried if it fails.
/// Typical use cases include retrying requests a given number of times in the event of poor network connectivity.
public class HTTPRequest<T: Decodable> {
    
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
    
    /// Triggers the request to actually be sent.
    public func run() async throws -> T {
        var request = self.request
        
        do {
            // Apply the adaptors to the request.
            request = try await ZipAdaptor(adaptors)
                .adapt(self.request, for: dispatcher.session)
            
            // Dispatch the request and wait for a response.
            let (data, response) = try await dispatcher.data(for: request)
            
            // Apply the validators to the response.
            try await ZipValidator(validators)
                .validate(response, for: request, with: data)
                .get()
            
            // Convert the data into the expected type.
            return try decoder.decode(T.self, from: data)
        } catch {
            let strategy = await ZipRetrier(retriers).retry(request, for: dispatcher.session, dueTo: error)
            switch strategy {
            case .concede:
                throw error
            case .retry:
                return try await run()
            }
        }
    }
    
    // MARK: Adapt
    
    /// Applies the provided adaptor to the request.
    public func adapt(with adaptor: any HTTPRequestAdaptor) -> Self {
        adaptors.append(adaptor)
        return self
    }
    
    /// Applies the provided adaptation handler to the request.
    public func adapt(_ handler: @escaping AdaptationHandler) -> Self {
        adaptors.append(Adaptor(handler))
        return self
    }
    
    // MARK: Retry
    
    /// Applies the provided retrier to the request's retry strategy.
    public func retry(with retrier: any HTTPRequestRetrier) -> Self {
        retriers.append(retrier)
        return self
    }
    
    /// Applies the provided retry handler to the request's retry strategy.
    public func retry(_ handler: @escaping RetryHandler) -> Self {
        retriers.append(Retrier(handler))
        return self
    }
    
    // MARK: Validate
    
    /// Applies the provided validator to the request's response validation.
    public func validate(with validator: any HTTPResponseValidator) -> Self {
        validators.append(validator)
        return self
    }
    
    /// Applies the provided validation handler to the request's response validation.
    public func validate(_ handler: @escaping ValidationHandler) -> Self {
        validators.append(Validator(handler))
        return self
    }
}
