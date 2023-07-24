@testable import HTTPNetworking
import XCTest

class ZipAdaptorTests: XCTestCase {
    func test_zippedAdaptor_withAdaptors_containsAdaptorsInOrder() {
        struct TestAdaptor: HTTPRequestAdaptor, Equatable {
            let id: Int
            func adapt(_ request: URLRequest, for session: URLSession) async throws -> URLRequest {
                return request
            }
        }
        
        let one = TestAdaptor(id: 1)
        let two = TestAdaptor(id: 1)
        let three = TestAdaptor(id: 1)
        let expectedAdaptor = [one, two, three]
        
        let zipAdaptor = ZipAdaptor(expectedAdaptor)
        XCTAssertEqual(zipAdaptor.adaptors as? [TestAdaptor], expectedAdaptor)
        
        let variadicZip = ZipAdaptor(one, two, three)
        XCTAssertEqual(variadicZip.adaptors as? [TestAdaptor], expectedAdaptor)
    }
}
