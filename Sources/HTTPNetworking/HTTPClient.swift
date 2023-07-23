import Foundation

/// `HTTPClient` creates and manages requests over the network.
///
/// The client also provides common functionality for all  ``HTTPRequest`` objects, including encoding and decoding strategies,
/// request adaptation, response validation and retry stratagies.
///
/// Generally an ``HTTPClient`` is used to manage the interaction with a single API service. Most APIs
/// have their own nuance and complexities, and encapsulating all of that in one place can help structure your code in a
/// more scalable and testable way.
///
/// If your API requires a custom encoder or decoder, you can provide your own custom ones to the client. These encoder and decoders
/// will then be used for all requests made using the client.
///
/// If your API requires some sort of repetitive task applied to each request, rather than manipulating it at each call, you can make use of an
/// ``HTTPRequestAdaptor``. The adaptors that you provide to the client will all be run on a request before it is sent to your API.
/// This provides you with an opportunity to insert various headers or perform asyncrounous tasks before sending the outbound request.
///
/// Different APIs require different forms of validation that help you determine if a request was successful or not.
/// The default ``HTTPClient`` makes no assumptions about the format and/or success of an API's response. Instead, you can make use of an
/// ``HTTPResponseValidator``. The validators that you provide the client will all be run on the response received by your API.
/// This provides you with an opportunity to determine wether or not the response was a success and failure, and consolidate potentially repeated logic in one place.
///
/// Sometimes you may want to implement logic for handling retries of failed requests. An ``HTTPClient`` can make use of an
/// ``HTTPRequestRetriers``. The retriers that you provide the client will be run when a request fails.
/// This provides you with an opportunity to observe the error and determine wether or not the request should be sent again. You can implement complex retry
/// logic across your entire client without having to repeat yourself.
///
/// In addition to providing adaptors, validators and retriers to your entire client, you can provide additional configuration to each
/// request using a chaining style syntax. This allows you to add additional configuration to endpoints that you may want to provide further
/// customization to beyond the standard configuration at the client level.
///
/// ```swift
/// // Create a client.
/// let client = HTTPClient()
///
/// // Create a request.
/// let request = client.request(for: .get, to: url, expecting: [Dog].self)
///     .adapt(with: adaptor)
///     .validate(with: validator)
///     .retry(with: retrier)
///
/// // Send a request.
/// let response = try await request.run()
/// ```
///
/// > Note: All adaptors, validators and retriers at the client level will be run first, after which the
/// request configurations at the request level will be run.
///
/// > Important: All adaptors will always run for every request.
///
/// > Important: Validators will be run one by one on a request's response. If any validators determines that the response is invalid,
/// the request will fail and throw the error returned by that validator. No other subsequent validators will be run for that run of a request.
///
/// > Important: Retriers will be run one by one in the event of a failred request. If any retrier concedes that the request should not be retried,
/// the request will ask the next retrier if the request should be retried. If any retrier determines that a request should be retired, the request will
/// immedietly be retired, without asking any subsequent retriers.
public struct HTTPClient {
    
    // MARK: Properties
    
    /// The encoder that each request uses to encode request bodies.
    public let encoder: JSONEncoder
    
    /// The decoder that each request uses to decode response bodies.
    public let decoder: JSONDecoder
    
    /// The dispatcher that sends out each request.
    public let dispatcher: HTTPDispatcher
    
    /// A collection of adaptors that adapt each request.
    public let adaptors: [any HTTPRequestAdaptor]
    
    /// A collection of retriers that handle retrying failed requests.
    public let retriers: [any HTTPRequestRetrier]
    
    /// A collection of validators that validate each response.
    public let validators: [any HTTPResponseValidator]
    
    // MARK: Initializers
    
    /// Creates an ``HTTPClient`` with the provided configuration.
    ///
    /// - Parameters:
    ///   - encoder: The encoder that each request should use to encode request bodies.
    ///   - decoder: The decoder that each request should use to decode response bodies.
    ///   - dispatcher: The dispatcher that will actually send out each request.
    ///   - adaptors: A collection of adaptors that adapt each request.
    ///   - retriers: A collection of retriers that handle retrying failed requests.
    ///   - validators: A collection of validators that validate each response.
    public init(
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder(),
        dispatcher: HTTPDispatcher = .live(),
        adaptors: [any HTTPRequestAdaptor] = [],
        retriers: [any HTTPRequestRetrier] = [],
        validators: [any HTTPResponseValidator] = []
    ) {
        self.encoder = encoder
        self.decoder = decoder
        self.dispatcher = dispatcher
        self.adaptors = adaptors
        self.retriers = retriers
        self.validators = validators
    }
    
    // MARK: Public

    /// Creates a request with a body.
    ///
    /// - Parameters:
    ///   - method: The ``HTTPMethod`` of the request.
    ///   - url: The url the request is being sent to.
    ///   - body: The object to encode into the body of the request.
    ///   - responseType: The expected type to be decoded from the response body.
    /// - Returns: An `HTTPRequest` with the provided configuration.
    public func request<T: Encodable, U: Decodable>(
        for method: HTTPMethod,
        to url: URL,
        with body: T,
        expecting responseType: U.Type
    ) async throws -> HTTPRequest<U> {
        try await request(
            method: method,
            url: url,
            body: try encoder.encode(body),
            responseType: responseType
        )
    }

    /// Creates a request without a body.
    ///
    /// - Parameters:
    ///   - method: The ``HTTPMethod`` of the request.
    ///   - url: The url the request is being sent to.
    ///   - responseType: The expected type to be decoded from the response body.
    /// - Returns: An `HTTPRequest` with the provided configuration.
    public func request<T: Decodable>(
        for method: HTTPMethod,
        to url: URL,
        expecting responseType: T.Type
    ) async throws -> HTTPRequest<T> {
        return try await request(
            method: method,
            url: url,
            body: nil,
            responseType: responseType
        )
    }

    // MARK: Private

    /// Creates a request with a body.
    ///
    /// - Parameters:
    ///   - method: The ``HTTPMethod`` of the request.
    ///   - url: The url the request is being sent to.
    ///   - body: The data to attach to the request's body.
    ///   - responseType: The expected type to be decoded from the response body.
    /// - Returns: An `HTTPRequest` with the provided configuration.
    private func request<T: Decodable>(
        method: HTTPMethod,
        url: URL,
        body: Data?,
        responseType: T.Type
    ) async throws -> HTTPRequest<T> {
        var request = URLRequest(url: url)
        
        if body != nil {
            assert(method != .get,"GET requests should not contain a body.")
        }
        
        request.httpMethod = method.rawValue
        request.httpBody = body
        return HTTPRequest(
            request: request,
            decoder: decoder,
            dispatcher: dispatcher,
            adaptors: adaptors,
            retriers: retriers,
            validators: validators
        )
    }
}