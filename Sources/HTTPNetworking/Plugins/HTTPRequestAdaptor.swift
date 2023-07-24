import Foundation

/// An ``HTTPRequestAdaptor`` is used to change a `URLRequest` before it is sent out by an ``HTTPClient``.
///
/// By conforming to ``HTTPRequestAdaptor`` you can implement both simple and complex logic for manipulating a `URLRequest`
/// before it is sent out over the network. Common use cases include manage the client's authorization status, or adding additional headers to a request.
public protocol HTTPRequestAdaptor {
    func adapt(_ request: URLRequest, for session: URLSession) async throws -> URLRequest
}
