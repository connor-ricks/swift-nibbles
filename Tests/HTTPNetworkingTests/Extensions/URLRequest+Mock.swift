import Foundation
import HTTPNetworking

extension URLRequest {
    static let mock = URLRequest(url: .mock)
    
    static func mock(method: HTTPMethod) -> URLRequest {
        var request = URLRequest(url: .mock)
        request.httpMethod = method.rawValue
        return request
    }
}
