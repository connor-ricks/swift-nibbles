import Foundation

#warning("TODO: URLQueryParameter Stratagies? Adaptor? Consumer responsibility with URL?")
#warning("TODO: Error Response Decoding Stratagies? Errors usually have a different format.")

/// `HTTPClient` creates and manages `HTTPRequests` during their lifetimes.
///
/// The client also provides common functionality for all `HTTPRequests`, including encoding and decoding stratagies,
/// request adaptation, response validation and retry stratagies.
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
    
    /// Creates an `HTTPClient` with the provided configuration.
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
    ///   - method: The `HTTPMethod` of the request.
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
    ///   - method: The `HTTPMethod` of the request.
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
    ///   - method: The `HTTPMethod` of the request.
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
