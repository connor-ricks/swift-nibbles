import Foundation

/// A type representing HTTP methods.
///
/// See [RFC 9110 - Section 9](https://www.rfc-editor.org/rfc/rfc9110.html#name-methods) for more information.
public struct HTTPMethod: RawRepresentable, Equatable, Hashable {
    /// The `GET` method requests a representation of the specified resource. Requests using GET should only retrieve data.
    public static let get = HTTPMethod(rawValue: "GET")
    
    /// The `HEAD` method asks for a response identical to that of a GET request, but without the response body.
    public static let head = HTTPMethod(rawValue: "HEAD")
    
    /// The `POST` method is used to submit an entity to the specified resource, often causing a change in state or side effects on the server.
    public static let post = HTTPMethod(rawValue: "POST")
    
    /// The `PUT` method replaces all current representations of the target resource with the request payload.
    public static let put = HTTPMethod(rawValue: "PUT")
    
    /// The `DELETE` method deletes the specified resource.
    public static let delete = HTTPMethod(rawValue: "DELETE")
    
    /// The `CONNECT` method establishes a tunnel to the server identified by the target resource.
    public static let connect = HTTPMethod(rawValue: "CONNECT")
    
    /// The `OPTIONS` method is used to describe the communication options for the target resource.
    public static let options = HTTPMethod(rawValue: "OPTIONS")
    
    /// The `TRACE` method performs a message loop-back test along the path to the target resource.
    public static let trace = HTTPMethod(rawValue: "TRACE")
    
    /// The `PATCH` method is used to apply partial modifications to a resource.
    public static let patch = HTTPMethod(rawValue: "PATCH")
    
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue.uppercased()
    }
}
