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
    
    func test_zipRetrier_whenCancelled_stopsIteratingThroughRetriers() async {
        var task: Task<Void, Error>?
        let retrierOneExpectation = expectation(description: "Expected retrier one to be executed.")
        let retrierTwoExpectation = expectation(description: "Expected retrier two to be executed.")
        
        let zipRetrier = ZipRetrier([
            Retrier { _, _, _ in
                retrierOneExpectation.fulfill()
                return .concede
            },
            Retrier { _, _, _ in
                retrierTwoExpectation.fulfill()
                task?.cancel()
                return .concede
            },
            Retrier { _, _, _ in
                XCTFail("Expected task to be cancelled and third retrier to be skipped.")
                return .concede
            }
        ])
        
        task = Task {
            do {
                _ = try await zipRetrier.retry(.mock, for: .shared, dueTo: URLError(.cannotParseResponse))
            } catch {
                XCTAssertTrue(error is CancellationError)
            }
        }
        
        await fulfillment(of: [retrierOneExpectation, retrierTwoExpectation])
    }
}
