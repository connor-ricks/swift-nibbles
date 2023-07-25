@testable import HTTPNetworking
import XCTest

class ZipRetrierTests: XCTestCase {
    func test_zipRetrier_withRetriers_containsRetriersInOrder() {
        struct TestRetrier: HTTPRequestRetrier, Equatable {
            let id: Int
            func retry(_ request: URLRequest, for session: URLSession, dueTo error: Error) async -> HTTPNetworking.RetryStrategy {
                .concede
            }
        }
        
        let one = TestRetrier(id: 1)
        let two = TestRetrier(id: 1)
        let three = TestRetrier(id: 1)
        let expectedRetriers = [one, two, three]
        
        let zipRetrier = ZipRetrier(expectedRetriers)
        XCTAssertEqual(zipRetrier.retriers as? [TestRetrier], expectedRetriers)
        
        let variadicZip = ZipRetrier(one, two, three)
        XCTAssertEqual(variadicZip.retriers as? [TestRetrier], expectedRetriers)
    }
}
