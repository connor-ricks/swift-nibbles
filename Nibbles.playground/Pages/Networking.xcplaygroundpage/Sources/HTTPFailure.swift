import Foundation

/// An error representing a non success status code from an HTTP request.
public struct HTTPFailure: Error {
    /// The HTTP status code.
    public let code: Int
    
    /// The API response data.
    public let data: Data
}
