import Foundation

#warning("[Improvement] Improve the Networker so that you can make use of other URLRequest properties like allowsExpensiveNetworkAccess and timeoutInterval.")
/// An object that can perform HTTP requests, translating responses into a given type.
public struct HTTPNetworker {
    
    // MARK: Properties
    
    /// Headers to be sent along with every request.
    public let headers: [String : String]
    
    /// A customized encoder for request content.
    public let encoder: JSONEncoder
    
    /// A customized decoder for response parsing.
    public let decoder: JSONDecoder
    
    /// The `HTTPFetcher` that sends out the requests.
    public let requestor: HTTPRequestor
    
    // MARK: Initializers
    
    public init(
        headers: [String : String] = [:],
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder(),
        requestor: HTTPRequestor = .live()
    ) {
        self.headers = headers
        self.encoder = encoder
        self.decoder = decoder
        self.requestor = requestor
    }
    
    // MARK: Public Request Methods

    /// Perform a request with a body.
    public func perform<T: Encodable, U: Decodable>(
        _ method: HTTPMethod,
        to url: URL,
        with body: T,
        expecting responseType: U.Type,
        additionalHeaders: [String: String] = [:]
    ) async throws -> U {
        return try await perform(
            method: method,
            url: url,
            body: try encoder.encode(body),
            responseType: responseType,
            additionalHeaders: additionalHeaders
        )
    }

    /// Perform a request without a body
    public func perform<T: Decodable>(
        _ method: HTTPMethod,
        to url: URL,
        expecting responseType: T.Type,
        additionalHeaders: [String: String] = [:]
    ) async throws -> T {
        return try await perform(
            method: method,
            url: url,
            body: nil,
            responseType: responseType,
            additionalHeaders: additionalHeaders
        )
    }

    // MARK: Private Request Methods

    /// Private request implementaiton
    private func perform<T: Decodable>(
        method: HTTPMethod,
        url: URL,
        body: Data?,
        responseType: T.Type,
        additionalHeaders: [String: String] = [:]
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        request.allHTTPHeaderFields = headers.merging(additionalHeaders, uniquingKeysWith: { $1 })
        if let body = body {
            assert(method != .get, "GET requests should not contain a body.")
            request.httpBody = body
        }

        let (data, response) = try await requestor.data(request)
        
        if response.statusCode < 200 || response.statusCode > 399 {
            throw HTTPFailure(code: response.statusCode, data: data)
        } else {
            return try decoder.decode(responseType, from: data)
        }
    }
}
