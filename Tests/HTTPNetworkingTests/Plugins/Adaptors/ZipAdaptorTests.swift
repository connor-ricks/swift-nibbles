@testable import HTTPNetworking
import XCTest

class ZipAdaptorTests: XCTestCase {
    func test_zipAdaptor_withAdaptors_containsAdaptorsInOrder() {
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
    
    func test_zipAdaptor_whenCancelled_stopsIteratingThroughAdaptors() async {
        var task: Task<Void, Error>?
        let adaptorOneExpectation = expectation(description: "Expected adaptor one to be executed.")
        let adaptorTwoExpectation = expectation(description: "Expected adaptor two to be executed.")
        
        let zipAdaptor = ZipAdaptor([
            Adaptor { request, _ in
                adaptorOneExpectation.fulfill()
                return request
            },
            Adaptor { request, _ in
                adaptorTwoExpectation.fulfill()
                task?.cancel()
                return request
            },
            Adaptor { request, _ in
                XCTFail("Expected task to be cancelled and third adaptor to be skipped.")
                return request
            }
        ])
        
        task = Task {
            do {
                _ = try await zipAdaptor.adapt(.mock, for: .shared)
            } catch {
                XCTAssertTrue(error is CancellationError)
            }
        }
        
        await fulfillment(of: [adaptorOneExpectation, adaptorTwoExpectation], enforceOrder: true)
    }
    
    func test_zipAdaptor_adaptorConvenience_isAddedToRequestAdaptors() async throws {
        let client = HTTPClient()
        let request = client.request(for: .get, to: .mock, expecting: String.self)
        let expectationOne = expectation(description: "Expected adaptor one to be called.")
        let expectationTwo = expectation(description: "Expected adaptor two to be called.")
        request.adapt(zipping: [
            Adaptor { request, _ in
                expectationOne.fulfill()
                return request
            },
            Adaptor { request, _ in
                expectationTwo.fulfill()
                return request
            },
        ])
        
        _ = try await request.adaptors.first?.adapt(request.request, for: client.dispatcher.session)
        
        await fulfillment(of: [expectationOne, expectationTwo], enforceOrder: true)
    }
}
