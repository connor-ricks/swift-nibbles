@testable import HTTPNetworking
import XCTest

class HTTPRequestTests: XCTestCase {
    
    // MARK: MockError
    
    struct MockError: Error, Equatable {
        let id: Int
    }
    
    // MARK: Properties
    
    let strings = ["Hello", "World", "!"]
    var data: Data { try! JSONEncoder().encode(strings) }
    
    // MARK: Successful Request Tests
    
    func test_request_whereRequestIsSuccessful_returnsExpectedResponse() async throws {
        let url = createMockUrl()
        
        let client = HTTPClient(dispatcher: .mock(responses: [
            url: .success(data: data, response: createResponse(for: url, with: 200)),
        ]))
        
        let response = try await client
            .request(for: .get, to: url, expecting: [String].self)
            .run()
        
        XCTAssertEqual(response, strings)
    }
    
    func test_request_whereRequestContainsBodyAndIsSuccessful_returnsExpectedResponse() async throws {
        let url = createMockUrl()
        
        let client = HTTPClient(dispatcher: .mock(responses: [
            url: .success(data: data, response: createResponse(for: url, with: 200)),
        ]))
        
        let response = try await client
            .request(for: .post, to: url, with: strings.reversed(), expecting: [String].self)
            .run()
        
        XCTAssertEqual(response, strings)
    }
    
    // MARK: Failed Request Tests
    
    func test_request_whereRequestIsUnsuccessful_throwsExpectedError() async throws {
        let url = createMockUrl()
        let expectedError = URLError(.cannotConnectToHost)
        
        let client = HTTPClient(dispatcher: .mock(responses: [
            url: .failure(expectedError)
        ]))
        
        do {
            _ = try await client
                .request(for: .get, to: url, expecting: [String].self)
                .run()
            XCTFail("Expected request to fail.")
        } catch let error as URLError {
            XCTAssertEqual(error.code, expectedError.code)
        } catch {
            XCTFail("Unexpected error thrown.")
        }
    }
    
    func test_request_whereRequestContainsBodyAndIsUnsuccessful_throwsExpectedError() async throws {
        let url = createMockUrl()
        let expectedError = URLError(.cannotConnectToHost)
        
        let client = HTTPClient(dispatcher: .mock(responses: [
            url: .failure(expectedError)
        ]))
        
        do {
            _ = try await client
                .request(for: .post, to: url, with: strings.reversed(), expecting: [String].self)
                .run()
            XCTFail("Expected request to fail.")
        } catch let error as URLError {
            XCTAssertEqual(error.code, expectedError.code)
        } catch {
            XCTFail("Unexpected error thrown.")
        }
    }
    
    // MARK: Adaptor Tests
    
    func test_client_withAdaptor_runsAdaptorOnRequest() async throws {
        let url = createMockUrl()
        let adaptationExpectation = expectation(description: "Expected adaptor to be called.")
        let receivedRequestExpectation = expectation(description: "Expected onRecieveRequest to be called.")
        
        var adaptedRequest: URLRequest?
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .success(
                    data: data,
                    response: createResponse(for: url, with: 200),
                    onRecieveRequest: {
                        XCTAssertEqual($0, adaptedRequest)
                        receivedRequestExpectation.fulfill()
                    }
                )
            ]),
            adaptors: [
                Adaptor { request, session in
                    var request = request
                    request.setValue("TEST-HEADER", forHTTPHeaderField: "TEST-VALUE")
                    adaptedRequest = request
                    adaptationExpectation.fulfill()
                    return request
                }
            ]
        )
        
        _ = try await client
            .request(for: .get, to: url, expecting: [String].self)
            .run()
        
        await fulfillment(of: [adaptationExpectation, receivedRequestExpectation])
    }
    
    func test_client_withMultipleAdaptors_runsAdaptorsInOrderOnRequest() async throws {
        let url = createMockUrl()
        let adaptorOneExpectation = expectation(description: "Expected adaptor one to be called.")
        let adaptorTwoExpectation = expectation(description: "Expected adaptor two to be called.")
        let adaptorThreeExpectation = expectation(description: "Expected adaptor three to be called.")
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .success(data: data, response: createResponse(for: url, with: 200))
            ]),
            adaptors: [
                Adaptor { request, session in
                    adaptorOneExpectation.fulfill()
                    return request
                },
                Adaptor { request, session in
                    adaptorTwoExpectation.fulfill()
                    return request
                },
                Adaptor { request, session in
                    adaptorThreeExpectation.fulfill()
                    return request
                }
            ]
        )
        
        _ = try await client
            .request(for: .get, to: url, expecting: [String].self)
            .run()
        
        await fulfillment(of: [
            adaptorOneExpectation,
            adaptorTwoExpectation,
            adaptorThreeExpectation
        ], enforceOrder: true)
    }
    
    func test_request_withAdaptor_runsAdaptorOnRequest() async throws {
        let url = createMockUrl()
        let adaptationExpectation = expectation(description: "Expected adaptor to be called.")
        let receivedRequestExpectation = expectation(description: "Expected onRecieveRequest to be called.")
        
        var adaptedRequest: URLRequest?
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .success(
                    data: data,
                    response: createResponse(for: url, with: 200),
                    onRecieveRequest: {
                        XCTAssertEqual($0, adaptedRequest)
                        receivedRequestExpectation.fulfill()
                    }
                )
            ])
        )
        
        let adaptor = Adaptor { request, session in
            var request = request
            request.setValue("TEST-HEADER", forHTTPHeaderField: "TEST-VALUE")
            adaptedRequest = request
            adaptationExpectation.fulfill()
            return request
        }
        
        _ = try await client
            .request(for: .get, to: url, expecting: [String].self)
            .adapt(with: adaptor)
            .run()
        
        await fulfillment(of: [adaptationExpectation, receivedRequestExpectation])
    }
    
    func test_request_withMultipleAdaptors_runsAdaptorsInOrderOnRequest() async throws {
        let url = createMockUrl()
        let adaptorOneExpectation = expectation(description: "Expected adaptor one to be called.")
        let adaptorTwoExpectation = expectation(description: "Expected adaptor two to be called.")
        let adaptorThreeExpectation = expectation(description: "Expected adaptor three to be called.")
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .success(data: data, response: createResponse(for: url, with: 200))
            ])
        )
        
        _ = try await client
            .request(for: .get, to: url, expecting: [String].self)
            .adapt(with: Adaptor { request, session in
                adaptorOneExpectation.fulfill()
                return request
            })
            .adapt(with: Adaptor { request, session in
                adaptorTwoExpectation.fulfill()
                return request
            })
            .adapt(with: Adaptor { request, session in
                adaptorThreeExpectation.fulfill()
                return request
            })
            .run()
        
        await fulfillment(of: [
            adaptorOneExpectation,
            adaptorTwoExpectation,
            adaptorThreeExpectation
        ], enforceOrder: true)
    }
    
    func test_request_whereClientAndRequestBothContainAdaptors_runsAdaptorsInOrderOnRequest() async throws {
        let url = createMockUrl()
        let adaptorOneExpectation = expectation(description: "Expected adaptor one to be called.")
        let adaptorTwoExpectation = expectation(description: "Expected adaptor two to be called.")
        let adaptorThreeExpectation = expectation(description: "Expected adaptor three to be called.")
        let adaptorFourExpectation = expectation(description: "Expected adaptor four to be called.")
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .success(data: data, response: createResponse(for: url, with: 200))
            ]),
            adaptors: [
                Adaptor { request, session in
                    adaptorOneExpectation.fulfill()
                    return request
                },
                Adaptor { request, session in
                    adaptorTwoExpectation.fulfill()
                    return request
                }
            ]
        )
        
        _ = try await client
            .request(for: .get, to: url, expecting: [String].self)
            .adapt(with: Adaptor { request, session in
                adaptorThreeExpectation.fulfill()
                return request
            })
            .adapt(with: Adaptor { request, session in
                adaptorFourExpectation.fulfill()
                return request
            })
            .run()
        
        await fulfillment(of: [
            adaptorOneExpectation,
            adaptorTwoExpectation,
            adaptorThreeExpectation,
            adaptorFourExpectation
        ], enforceOrder: true)
    }
    
    // MARK: Validator Tests
    
    func test_client_withSuccessfulValidator_runsValidatorOnRequestAndReturnsSuccessfully() async throws {
        let url = createMockUrl()
        let expectedResponse = createResponse(
            for: url,
            with: 200,
            headerFields: ["TEST-HEADER": "TEST-VALUE"]
        )
        
        let validatorExpectation = expectation(description: "Expected validator to be called.")
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .success(data: data, response: expectedResponse)
            ]),
            validators: [
                Validator { response, request, data in
                    let header = response.value(forHTTPHeaderField: "TEST-HEADER")
                    XCTAssertEqual(header, "TEST-VALUE")
                    validatorExpectation.fulfill()
                    return .success
                }
            ]
        )
        
        _ = try await client
            .request(for: .get, to: url, expecting: [String].self)
            .run()
        
        await fulfillment(of: [validatorExpectation])
    }
    
    func test_client_withUnsuccessfulValidator_runsValidatorOnRequestAndThrowsError() async throws {
        let url = createMockUrl()
        
        let expectedError = MockError(id: 1)
        let validatorExpectation = expectation(description: "Expected validator to be called.")
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .success(data: data, response: createResponse(for: url,with: 200))
            ]),
            validators: [
                Validator { response, request, data in
                    validatorExpectation.fulfill()
                    return .failure(expectedError)
                }
            ]
        )
        
        do {
            _ = try await client
                .request(for: .get, to: url, expecting: [String].self)
                .run()
            XCTFail("Expected request to throw an error.")
        } catch {
            XCTAssertEqual(error as? MockError, expectedError)
        }
        
        await fulfillment(of: [validatorExpectation])
    }
    
    func test_client_withSuccessfulAndUnsuccessfulValidators_runValidatorsInOrderOnRequest() async throws {
        let url = createMockUrl()
        
        let expectedError = MockError(id: 1)
        let validatorOneExpectation = expectation(description: "Expected validator one to be called.")
        let validatorTwoExpectation = expectation(description: "Expected validator two to be called.")
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .success(data: data, response: createResponse(for: url,with: 200))
            ]),
            validators: [
                Validator { response, request, data in
                    validatorOneExpectation.fulfill()
                    return .success
                },
                Validator { response, request, data in
                    validatorTwoExpectation.fulfill()
                    return .failure(expectedError)
                }
            ]
        )
        
        do {
            _ = try await client
                .request(for: .get, to: url, expecting: [String].self)
                .run()
            XCTFail("Expected request to throw an error.")
        } catch {
            XCTAssertEqual(error as? MockError, expectedError)
        }
        
        await fulfillment(of: [validatorOneExpectation, validatorTwoExpectation], enforceOrder: true)
    }
    
    func test_client_withUnsuccessfulAndSuccessfulValidators_runsOnlyFirstValidatorOnRequest() async throws {
        let url = createMockUrl()
        
        let expectedError = MockError(id: 1)
        let validatorOneExpectation = expectation(description: "Expected validator one to be called.")
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .success(data: data, response: createResponse(for: url,with: 200))
            ]),
            validators: [
                Validator { response, request, data in
                    validatorOneExpectation.fulfill()
                    return .failure(expectedError)
                },
                Validator { response, request, data in
                    XCTFail("Expected previous validator to fail, ignoring this one.")
                    return .success
                }
            ]
        )
        
        do {
            _ = try await client
                .request(for: .get, to: url, expecting: [String].self)
                .run()
            XCTFail("Expected request to throw an error.")
        } catch {
            XCTAssertEqual(error as? MockError, expectedError)
        }
        
        await fulfillment(of: [validatorOneExpectation])
    }
    
    func test_client_withUnsuccessfulAndUnsuccessfulValidators_runsOnlyFirstValidatorOnRequest() async throws {
        let url = createMockUrl()
        
        let expectedError = MockError(id: 1)
        let validatorOneExpectation = expectation(description: "Expected validator one to be called.")
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .success(data: data, response: createResponse(for: url,with: 200))
            ]),
            validators: [
                Validator { response, request, data in
                    validatorOneExpectation.fulfill()
                    return .failure(expectedError)
                },
                Validator { response, request, data in
                    XCTFail("Expected previous validator to fail, ignoring this one.")
                    return .failure(expectedError)
                }
            ]
        )
        
        do {
            _ = try await client
                .request(for: .get, to: url, expecting: [String].self)
                .run()
            XCTFail("Expected request to throw an error.")
        } catch {
            XCTAssertEqual(error as? MockError, expectedError)
        }
        
        await fulfillment(of: [validatorOneExpectation])
    }
    
    func test_client_withSuccessfulValidators_runValidatorsInOrderOnRequest() async throws {
        let url = createMockUrl()
        
        let validatorOneExpectation = expectation(description: "Expected validator one to be called.")
        let validatorTwoExpectation = expectation(description: "Expected validator two to be called.")
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .success(data: data, response: createResponse(for: url,with: 200))
            ]),
            validators: [
                Validator { response, request, data in
                    validatorOneExpectation.fulfill()
                    return .success
                },
                Validator { response, request, data in
                    validatorTwoExpectation.fulfill()
                    return .success
                }
            ]
        )
        
        do {
            _ = try await client
                .request(for: .get, to: url, expecting: [String].self)
                .run()
        } catch {
            XCTFail("Expected request to complete without throwing an error.")
        }
        
        await fulfillment(of: [validatorOneExpectation, validatorTwoExpectation], enforceOrder: true)
    }
    
    func test_request_withSuccessfulValidator_runsValidatorOnRequestAndReturnsSuccessfully() async throws {
        let url = createMockUrl()
        
        let validatorExpectation = expectation(description: "Expected validator to be called.")
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .success(data: data, response: createResponse(for: url, with: 200))
            ])
        )
        
        _ = try await client
            .request(for: .get, to: url, expecting: [String].self)
            .validate(with: Validator { response, request, data in
                validatorExpectation.fulfill()
                return .success
            })
            .run()
        
        await fulfillment(of: [validatorExpectation])
    }
    
    func test_request_withUnsuccessfulValidator_runsValidatorOnRequestAndThrowsError() async throws {
        let url = createMockUrl()
        
        let expectedError = MockError(id: 1)
        let validatorExpectation = expectation(description: "Expected validator to be called.")
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .success(data: data, response: createResponse(for: url,with: 200))
            ])
        )
        
        do {
            _ = try await client
                .request(for: .get, to: url, expecting: [String].self)
                .validate(with: Validator { response, request, data in
                    validatorExpectation.fulfill()
                    return .failure(expectedError)
                })
                .run()
            XCTFail("Expected request to throw an error.")
        } catch {
            XCTAssertEqual(error as? MockError, expectedError)
        }
        
        await fulfillment(of: [validatorExpectation])
    }
    
    func test_request_whereClientAndRequestBothContainSuccessfulValidators_runsValidatorsInOrderOnRequest() async throws {
        let url = createMockUrl()
        
        let validatorOne = expectation(description: "Expected validator one to be called.")
        let validatorTwo = expectation(description: "Expected validator two to be called.")
        let validatorThree = expectation(description: "Expected validator three to be called.")
        let validatorFour = expectation(description: "Expected validator four to be called.")
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .success(data: data, response: createResponse(for: url, with: 200))
            ]),
            validators: [
                Validator { response, request, data in
                    validatorOne.fulfill()
                    return .success
                },
                Validator { response, request, data in
                    validatorTwo.fulfill()
                    return .success
                },
            ]
        )
        
        _ = try await client
            .request(for: .get, to: url, expecting: [String].self)
            .validate(with: Validator { response, request, data in
                validatorThree.fulfill()
                return .success
            })
            .validate(with: Validator { response, request, data in
                validatorFour.fulfill()
                return .success
            })
            .run()
        
        await fulfillment(of: [
            validatorOne,
            validatorTwo,
            validatorThree,
            validatorFour
        ], enforceOrder: true)
    }
    
    // MARK: Retrier Tests
    
    func test_client_withRetrier_runsRetrierOnRequestAndSuccessfullyRetries() async throws {
        let url = createMockUrl()
        let expectedError = URLError(.cannotConnectToHost)
        let retryExpectation = expectation(description: "Expected retry to be called.")
        var shouldRequestFail = true
        
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .init(result: {
                    if shouldRequestFail {
                        return .failure(expectedError)
                    } else {
                        return .success((self.data, self.createResponse(for: url, with: 200)))
                    }
                })
            ]),
            retriers: [
                Retrier { request, session, error in
                    XCTAssertEqual((error as? URLError)?.code, expectedError.code)
                    retryExpectation.fulfill()
                    shouldRequestFail = false
                    return .retry
                }
            ]
        )
        
        _ = try await client
            .request(for: .get, to: url, expecting: [String].self)
            .run()
        
        await fulfillment(of: [retryExpectation])
    }
    
    func test_client_withRetrier_runsRetrierOnRequestAndConcedesToFailure() async throws {
        let url = createMockUrl()
        let expectedError = URLError(.cannotConnectToHost)
        let retryExpectation = expectation(description: "Expected retry to be called.")
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .failure(expectedError)
            ]),
            retriers: [
                Retrier { request, session, error in
                    XCTAssertEqual((error as? URLError)?.code, expectedError.code)
                    retryExpectation.fulfill()
                    return .concede
                }
            ]
        )
        
        do {
            _ = try await client
                .request(for: .get, to: url, expecting: [String].self)
                .run()
            XCTFail("Expected request to fail after retry conceded.")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, expectedError.code)
        }
        
        await fulfillment(of: [retryExpectation])
    }
    
    func test_client_withMultipleRetriersSuccessfulAndConceding_runsFirstRetrierOnRequestAndNotSecond() async throws {
        let url = createMockUrl()
        let expectedError = URLError(.cannotConnectToHost)
        let retryExpectation = expectation(description: "Expected retry to be called.")
        var shouldRequestFail = true
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .init(result: {
                    if shouldRequestFail {
                        return .failure(expectedError)
                    } else {
                        return .success((self.data, self.createResponse(for: url, with: 200)))
                    }
                })
            ]),
            retriers: [
                Retrier { request, session, error in
                    XCTAssertEqual((error as? URLError)?.code, expectedError.code)
                    retryExpectation.fulfill()
                    shouldRequestFail = false
                    return .retry
                },
                Retrier { request, session, error in
                    XCTFail("Second retrier should not have been called.")
                    return .concede
                }
            ]
        )
        
        _ = try await client
            .request(for: .get, to: url, expecting: [String].self)
            .run()
        
        await fulfillment(of: [retryExpectation])
    }
    
    func test_client_withMultipleRetriersConcedingAndSuccessful_runsBothRetriersOnRequest() async throws {
        let url = createMockUrl()
        let expectedError = URLError(.cannotConnectToHost)
        let retrierOneExpectation = expectation(description: "Expected retrier one to be called.")
        let retrierTwoExpectation = expectation(description: "Expected retrier two to be called.")
        var shouldRequestFail = true
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .init(result: {
                    if shouldRequestFail {
                        return .failure(expectedError)
                    } else {
                        return .success((self.data, self.createResponse(for: url, with: 200)))
                    }
                })
            ]),
            retriers: [
                Retrier { request, session, error in
                    XCTAssertEqual((error as? URLError)?.code, expectedError.code)
                    retrierOneExpectation.fulfill()
                    return .concede
                },
                Retrier { request, session, error in
                    XCTAssertEqual((error as? URLError)?.code, expectedError.code)
                    retrierTwoExpectation.fulfill()
                    shouldRequestFail = false
                    return .retry
                }
            ]
        )
        
        _ = try await client
            .request(for: .get, to: url, expecting: [String].self)
            .run()
        
        await fulfillment(of: [retrierOneExpectation, retrierTwoExpectation])
    }
    
    func test_request_withRetrier_runsRetrierOnRequestAndSuccessfullyRetries() async throws {
        let url = createMockUrl()
        let expectedError = URLError(.cannotConnectToHost)
        let retryExpectation = expectation(description: "Expected retry to be called.")
        var shouldRequestFail = true
        
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .init(result: {
                    if shouldRequestFail {
                        return .failure(expectedError)
                    } else {
                        return .success((self.data, self.createResponse(for: url, with: 200)))
                    }
                })
            ])
        )
        
        _ = try await client
            .request(for: .get, to: url, expecting: [String].self)
            .retry(with: Retrier { request, session, error in
                XCTAssertEqual((error as? URLError)?.code, expectedError.code)
                retryExpectation.fulfill()
                shouldRequestFail = false
                return .retry
            })
            .run()
        
        await fulfillment(of: [retryExpectation])
    }
    
    func test_request_withRetrier_runsRetrierOnRequestAndConcedesToFailure() async throws {
        let url = createMockUrl()
        let expectedError = URLError(.cannotConnectToHost)
        let retryExpectation = expectation(description: "Expected retry to be called.")
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .failure(expectedError)
            ])
        )
        
        do {
            _ = try await client
                .request(for: .get, to: url, expecting: [String].self)
                .retry(with: Retrier { request, session, error in
                    XCTAssertEqual((error as? URLError)?.code, expectedError.code)
                    retryExpectation.fulfill()
                    return .concede
                })
                .run()
            XCTFail("Expected request to fail after retry conceded.")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, expectedError.code)
        }
        
        await fulfillment(of: [retryExpectation])
    }
    
    func test_request_withMultipleRetriersSuccessfulAndConceding_runsFirstRetrierOnRequestAndNotSecond() async throws {
        let url = createMockUrl()
        let expectedError = URLError(.cannotConnectToHost)
        let retryExpectation = expectation(description: "Expected retry to be called.")
        var shouldRequestFail = true
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .init(result: {
                    if shouldRequestFail {
                        return .failure(expectedError)
                    } else {
                        return .success((self.data, self.createResponse(for: url, with: 200)))
                    }
                })
            ])
        )
        
        _ = try await client
            .request(for: .get, to: url, expecting: [String].self)
            .retry(with: Retrier { request, session, error in
                XCTAssertEqual((error as? URLError)?.code, expectedError.code)
                retryExpectation.fulfill()
                shouldRequestFail = false
                return .retry
            })
            .retry(with: Retrier { request, session, error in
                XCTFail("Second retrier should not have been called.")
                return .concede
            })
            .run()
        
        await fulfillment(of: [retryExpectation])
    }
    
    func test_request_withMultipleRetriersConcedingAndSuccessful_runsBothRetriersOnRequest() async throws {
        let url = createMockUrl()
        let expectedError = URLError(.cannotConnectToHost)
        let retrierOneExpectation = expectation(description: "Expected retrier one to be called.")
        let retrierTwoExpectation = expectation(description: "Expected retrier two to be called.")
        var shouldRequestFail = true
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .init(result: {
                    if shouldRequestFail {
                        return .failure(expectedError)
                    } else {
                        return .success((self.data, self.createResponse(for: url, with: 200)))
                    }
                })
            ])
        )
        
        _ = try await client
            .request(for: .get, to: url, expecting: [String].self)
            .retry(with: Retrier { request, session, error in
                XCTAssertEqual((error as? URLError)?.code, expectedError.code)
                retrierOneExpectation.fulfill()
                return .concede
            })
            .retry(with: Retrier { request, session, error in
                XCTAssertEqual((error as? URLError)?.code, expectedError.code)
                retrierTwoExpectation.fulfill()
                shouldRequestFail = false
                return .retry
            })
            .run()
        
        await fulfillment(of: [retrierOneExpectation, retrierTwoExpectation])
    }
    
    func test_request_withMultipleClientAndRequestRetriers_runsAllRetriersOnRequest() async throws {
        let url = createMockUrl()
        let expectedError = URLError(.cannotConnectToHost)
        let retrierOneExpectation = expectation(description: "Expected retrier one to be called.")
        let retrierTwoExpectation = expectation(description: "Expected retrier two to be called.")
        let retrierThreeExpectation = expectation(description: "Expected retrier three to be called.")
        let retrierFourExpectation = expectation(description: "Expected retrier four to be called.")
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .failure(expectedError)
            ]),
            retriers: [
                Retrier { request, session, error in
                    retrierOneExpectation.fulfill()
                    return .concede
                },
                Retrier { request, session, error in
                    retrierTwoExpectation.fulfill()
                    return .concede
                }
            ]
        )
        
        do {
            _ = try await client
                .request(for: .get, to: url, expecting: [String].self)
                .retry(with: Retrier { request, session, error in
                    retrierThreeExpectation.fulfill()
                    return .concede
                })
                .retry(with: Retrier { request, session, error in
                    retrierFourExpectation.fulfill()
                    return .concede
                })
                .run()
            XCTFail("Expected all retriers to concde and request to fail.")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, expectedError.code)
        }
        
        await fulfillment(of: [
            retrierOneExpectation,
            retrierTwoExpectation,
            retrierThreeExpectation,
            retrierFourExpectation,
        ])
    }
    
    // MARK: Task Cancellation Tests
    
    func test_request_whenCancelledBeforeAdaptorsFinish_doesNotProceed() async throws {
        let url = createMockUrl()
        let expectation = expectation(description: "Expected task cancellation error.")
        var task: Task<Void, Error>?
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .init(
                    result: .success((data, createResponse(for: url, with: 200))),
                    onRecieveRequest: { _ in
                        XCTFail("Request should not have been sent after task cancellation.")
                    }
                ),
            ]),
            adaptors: [
                Adaptor { request, _ in
                    task?.cancel()
                    return request
                },
                Adaptor { request, _ in
                    XCTFail("Second adaptor should not have been called after task cancellation.")
                    return request
                },
            ],
            retriers: [
                Retrier { _, _, _ in
                    XCTFail("Retrier should not have been called after task cancellation.")
                    return .concede
                }
            ],
            validators: [
                Validator { _, _, _ in
                    XCTFail("Validator should not have been called after task cancellation.")
                    return .success
                }
            ]
        )
        
        task = Task {
            do {
                _ = try await client
                    .request(for: .get, to: url, expecting: [String].self)
                    .run()
            } catch {
                XCTAssertTrue(error is CancellationError)
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation])
    }
    
    func test_request_whenCancelledBeforeValidatorsFinish_doesNotProceed() async throws {
        let url = createMockUrl()
        let expectation = expectation(description: "Expected task cancellation error.")
        var task: Task<Void, Error>?
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .init(
                    result: .success((data, createResponse(for: url, with: 200)))
                )
            ]),
            retriers: [
                Retrier { _, _, _ in
                    XCTFail("Retrier should not have been called after task cancellation.")
                    return .concede
                }
            ],
            validators: [
                Validator { _, _, _ in
                    task?.cancel()
                    return .success
                },
                Validator { _, _, _ in
                    XCTFail("Second validator should not have been called after task cancellation.")
                    return .success
                }
            ]
        )
        
        task = Task {
            do {
                _ = try await client
                    .request(for: .get, to: url, expecting: [String].self)
                    .run()
            } catch {
                XCTAssertTrue(error is CancellationError)
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation])
    }
    
    func test_request_whenCancelledBeforeRetriersFinish_doesNotProceed() async throws {
        let url = createMockUrl()
        let expectation = expectation(description: "Expected task cancellation error.")
        var task: Task<Void, Error>?
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .init(
                    result: .failure(URLError(.cannotParseResponse))
                )
            ]),
            retriers: [
                Retrier { _, _, _ in
                    task?.cancel()
                    return .concede
                },
                Retrier { _, _, _ in
                    XCTFail("Second retrier should not have been called after task cancellation.")
                    return .concede
                },
            ]
        )
        
        task = Task {
            do {
                _ = try await client
                    .request(for: .get, to: url, expecting: [String].self)
                    .run()
            } catch {
                XCTAssertTrue(error is CancellationError)
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation])
    }
    
    // MARK: Helpers
    
    func createMockUrl() -> URL {
        .mock.appending(component: UUID().uuidString)
    }
    
    func createResponse(for url: URL, with code: Int, headerFields: [String : String] = [:]) -> HTTPURLResponse {
        HTTPURLResponse(
            url: url,
            statusCode: code,
            httpVersion: nil,
            headerFields: headerFields
        )!
    }
}
