@testable import HTTPNetworking
import XCTest

class RetryStrategyTests: XCTestCase {
    func test_retryStrategy_whereMethodMatchesAndErrorMatchesAndStatusMatches_shouldRetry() async throws {
        let strategy = RetryStrategy(
            attempts: 3,
            methods: [.get],
            urlErrorCodes: [.networkConnectionLost],
            statusCodes: [418],
            exponentialBackoffBase: 1,
            jitterStrategy: .none
        )
        
        let decision = try await strategy.retry(
            .mock(method: .get),
            for: .shared,
            with: HTTPURLResponse(url: .mock, statusCode: 418, httpVersion: nil, headerFields: nil),
            dueTo: URLError(.networkConnectionLost),
            previousAttempts: 0
        )
        
        XCTAssertEqual(decision, .retryAfterDelay(.seconds(1)))
    }
    
    func test_retryStrategy_whereMethodMatchesAndErrorMatchesAndStatusDoesNotMatch_shouldRetry() async throws {
        let strategy = RetryStrategy(
            attempts: 3,
            methods: [.get],
            urlErrorCodes: [.networkConnectionLost],
            statusCodes: [],
            exponentialBackoffBase: 1,
            jitterStrategy: .none
        )
        
        let decision = try await strategy.retry(
            .mock(method: .get),
            for: .shared,
            with: nil,
            dueTo: URLError(.networkConnectionLost),
            previousAttempts: 0
        )
        
        XCTAssertEqual(decision, .retryAfterDelay(.seconds(1)))
    }
    
    func test_retryStrategy_whereMethodMatchesAndErrorDoesNotMatchAndStatusMatches_shouldRetry() async throws {
        let strategy = RetryStrategy(
            attempts: 3,
            methods: [.get],
            urlErrorCodes: [],
            statusCodes: [418],
            exponentialBackoffBase: 1,
            jitterStrategy: .none
        )
        
        let decision = try await strategy.retry(
            .mock(method: .get),
            for: .shared,
            with: HTTPURLResponse(url: .mock, statusCode: 418, httpVersion: nil, headerFields: nil),
            dueTo: URLError(.networkConnectionLost),
            previousAttempts: 0
        )
        
        XCTAssertEqual(decision, .retryAfterDelay(.seconds(1)))
    }
    
    func test_retryStrategy_whereMethodDoesNotMatchAndErrorMatchesAndStatusMatches_shouldConcede() async throws {
        let strategy = RetryStrategy(
            attempts: 3,
            methods: [],
            urlErrorCodes: [.networkConnectionLost],
            statusCodes: [418],
            exponentialBackoffBase: 1,
            jitterStrategy: .none
        )
        
        let decision = try await strategy.retry(
            .mock(method: .get),
            for: .shared,
            with: HTTPURLResponse(url: .mock, statusCode: 418, httpVersion: nil, headerFields: nil),
            dueTo: URLError(.networkConnectionLost),
            previousAttempts: 0
        )
        
        XCTAssertEqual(decision, .concede)
    }
    
    func test_retryStrategy_whereMethodDoesNotMatchAndErrorDoesNotMatchAndStatusMatches_shouldConcded() async throws {
        let strategy = RetryStrategy(
            attempts: 3,
            methods: [],
            urlErrorCodes: [],
            statusCodes: [418],
            exponentialBackoffBase: 1,
            jitterStrategy: .none
        )
        
        let decision = try await strategy.retry(
            .mock(method: .get),
            for: .shared,
            with: HTTPURLResponse(url: .mock, statusCode: 418, httpVersion: nil, headerFields: nil),
            dueTo: URLError(.networkConnectionLost),
            previousAttempts: 0
        )
        
        XCTAssertEqual(decision, .concede)
    }
    
    func test_retryStrategy_whereMethodDoesNotMatchAndErrorMatchesAndStatusDoesNotMatch_shouldConcede() async throws {
        let strategy = RetryStrategy(
            attempts: 3,
            methods: [],
            urlErrorCodes: [.networkConnectionLost],
            statusCodes: [],
            exponentialBackoffBase: 1,
            jitterStrategy: .none
        )
        
        let decision = try await strategy.retry(
            .mock(method: .get),
            for: .shared,
            with: HTTPURLResponse(url: .mock, statusCode: 418, httpVersion: nil, headerFields: nil),
            dueTo: URLError(.networkConnectionLost),
            previousAttempts: 0
        )
        
        XCTAssertEqual(decision, .concede)
    }
    
    func test_retryStrategy_whereMethodMatchesAndErrorDoesNotMatchAndStatusDoesNotMatch_shouldConcdede() async throws {
        let strategy = RetryStrategy(
            attempts: 3,
            methods: [.get],
            urlErrorCodes: [],
            statusCodes: [],
            exponentialBackoffBase: 1,
            jitterStrategy: .none
        )
        
        let decision = try await strategy.retry(
            .mock(method: .get),
            for: .shared,
            with: HTTPURLResponse(url: .mock, statusCode: 418, httpVersion: nil, headerFields: nil),
            dueTo: URLError(.networkConnectionLost),
            previousAttempts: 0
        )
        
        XCTAssertEqual(decision, .concede)
    }
    
    func test_retryStrategy_whereMethodDoesNotMatchAndErrorDoesNotMatchAndStatusDoesNotMatch_shouldConcede() async throws {
        let strategy = RetryStrategy(
            attempts: 3,
            methods: [],
            urlErrorCodes: [],
            statusCodes: [],
            exponentialBackoffBase: 1,
            jitterStrategy: .none
        )
        
        let decision = try await strategy.retry(
            .mock(method: .get),
            for: .shared,
            with: HTTPURLResponse(url: .mock, statusCode: 418, httpVersion: nil, headerFields: nil),
            dueTo: URLError(.networkConnectionLost),
            previousAttempts: 0
        )
        
        XCTAssertEqual(decision, .concede)
    }
    
    func test_retryStrategy_shouldRetryButAttemptsIsAtTheLimit_shouldConcdede() async throws {
        let strategy = RetryStrategy(
            attempts: 1,
            methods: [.get],
            urlErrorCodes: [.networkConnectionLost],
            statusCodes: [418],
            exponentialBackoffBase: 1,
            jitterStrategy: .none
        )
        
        let decision = try await strategy.retry(
            .mock(method: .get),
            for: .shared,
            with: HTTPURLResponse(url: .mock, statusCode: 418, httpVersion: nil, headerFields: nil),
            dueTo: URLError(.networkConnectionLost),
            previousAttempts: 1
        )
        
        XCTAssertEqual(decision, .concede)
    }
    
    func test_retryStrategy_shouldRetryButAttemptsIsGreaterThanTheLimit_shouldConcdede() async throws {
        let strategy = RetryStrategy(
            attempts: 1,
            methods: [.get],
            urlErrorCodes: [.networkConnectionLost],
            statusCodes: [418],
            exponentialBackoffBase: 1,
            jitterStrategy: .none
        )
        
        let decision = try await strategy.retry(
            .mock(method: .get),
            for: .shared,
            with: HTTPURLResponse(url: .mock, statusCode: 418, httpVersion: nil, headerFields: nil),
            dueTo: URLError(.networkConnectionLost),
            previousAttempts: 2
        )
        
        XCTAssertEqual(decision, .concede)
    }
    
    func test_retryStrategy_exponentialBackOff_increasesWithEachRetry() async throws {
        let strategy = RetryStrategy(
            attempts: 5,
            methods: [.get],
            urlErrorCodes: [.networkConnectionLost],
            statusCodes: [418],
            exponentialBackoffBase: 2,
            jitterStrategy: .none
        )
        
        let expectedDelays = [2, 4, 8, 16]
        for index in 0...3 {
            let decision = try await strategy.retry(
                .mock(method: .get),
                for: .shared,
                with: HTTPURLResponse(url: .mock, statusCode: 418, httpVersion: nil, headerFields: nil),
                dueTo: URLError(.networkConnectionLost),
                previousAttempts: index + 1
            )
         
            print(decision)
            XCTAssertEqual(decision, .retryAfterDelay(.seconds(expectedDelays[index])))
        }
    }
    
    func test_none_jitterStrategyJitter_returnsUntouchedDuration() {
        let jitter = RetryStrategy.JitterStrategy.none.jitter(for: 1)
        XCTAssertEqual(jitter, 1)
    }
    
    func test_full_jitterStrategyJitter_returnsDurationBetweenZeroAndProvidedDuration() {
        for _ in 0...999 {
            let jitter = RetryStrategy.JitterStrategy.full.jitter(for: 5)
            XCTAssertTrue((0...5).contains(jitter))
        }
    }
    
    func test_equal_jitterStrategyJitter_returnsDurationBetweenHalfDurationAndProvidedDuration() {
        for _ in 0...999 {
            let jitter = RetryStrategy.JitterStrategy.equal.jitter(for: 5)
            XCTAssertTrue((2.5...5).contains(jitter))
        }
    }
    
    func test_retryStrategy_retrierConvenience_isAddedToRequestRetriers() async throws {
        let client = HTTPClient(dispatcher: .mock(responses: [.mock: .failure(URLError(.badURL))]))
        let request = client.request(for: .get, to: .mock, expecting: String.self)
        request.retryStrategy(
            attempts: 999,
            methods: [.get],
            urlErrorCodes: [.badURL],
            statusCodes: [401],
            exponentialBackoffBase: 1,
            jitterStrategy: .full
        )
        
        guard let retrier = request.retriers.first as? RetryStrategy else {
            XCTFail("Expected first retrier to be a RetryStrategy.")
            return
        }
        
        XCTAssertEqual(retrier.attempts, 999)
        XCTAssertEqual(retrier.methods, [.get])
        XCTAssertEqual(retrier.urlErrorCodes, [.badURL])
        XCTAssertEqual(retrier.statusCodes, [401])
        XCTAssertEqual(retrier.exponentialBackoffBase, 1)
        XCTAssertEqual(retrier.jitterStrategy, .full)
    }
}
