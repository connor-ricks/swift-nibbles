// MIT License
//
// Copyright (c) 2023 Connor Ricks
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

@testable import Exchange
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
                Adaptor { request, _ in
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
                Adaptor { request, _ in
                    adaptorOneExpectation.fulfill()
                    return request
                },
                Adaptor { request, _ in
                    adaptorTwoExpectation.fulfill()
                    return request
                },
                Adaptor { request, _ in
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
        
        let adaptor = Adaptor { request, _ in
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
            .adapt(with: Adaptor { request, _ in
                adaptorOneExpectation.fulfill()
                return request
            })
            .adapt(with: Adaptor { request, _ in
                adaptorTwoExpectation.fulfill()
                return request
            })
            .adapt(with: Adaptor { request, _ in
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
                Adaptor { request, _ in
                    adaptorOneExpectation.fulfill()
                    return request
                },
                Adaptor { request, _ in
                    adaptorTwoExpectation.fulfill()
                    return request
                }
            ]
        )
        
        _ = try await client
            .request(for: .get, to: url, expecting: [String].self)
            .adapt(with: Adaptor { request, _ in
                adaptorThreeExpectation.fulfill()
                return request
            })
            .adapt(with: Adaptor { request, _ in
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
    
    func test_client_whereAdaptorThrows_catchesExpectedError() async throws {
        let url = createMockUrl()
        let expectedError = MockError(id: 1)
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .success(data: data, response: createResponse(for: url, with: 200))
            ]),
            adaptors: [
                Adaptor { _, _ in
                    throw expectedError
                }
            ]
        )
        
        do {
            _ = try await client
                .request(for: .get, to: url, expecting: [String].self)
                .run()
        } catch {
            XCTAssertEqual(error as? MockError, expectedError)
        }
    }
    
    func test_request_whereAdaptorThrows_catchesExpectedError() async throws {
        let url = createMockUrl()
        let expectedError = MockError(id: 1)
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .success(data: data, response: createResponse(for: url, with: 200))
            ])
        )
        
        do {
            _ = try await client
                .request(for: .get, to: url, expecting: [String].self)
                .adapt { _, _ in
                    throw expectedError
                }
                .run()
        } catch {
            XCTAssertEqual(error as? MockError, expectedError)
        }
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
                Validator { response, _, _ in
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
                Validator { response, _, _ in
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
                Validator { _, _, _ in
                    validatorOneExpectation.fulfill()
                    return .success
                },
                Validator { _, _, _ in
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
                Validator { _, _, _ in
                    validatorOneExpectation.fulfill()
                    return .failure(expectedError)
                },
                Validator { _, _, _ in
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
                Validator { _, _, _ in
                    validatorOneExpectation.fulfill()
                    return .failure(expectedError)
                },
                Validator { _, _, _ in
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
                Validator { _, _, _ in
                    validatorOneExpectation.fulfill()
                    return .success
                },
                Validator { _, _, _ in
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
            .validate(with: Validator { _, _, _ in
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
                .validate(with: Validator { _, _, _ in
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
                Validator { _, _, _ in
                    validatorOne.fulfill()
                    return .success
                },
                Validator { _, _, _ in
                    validatorTwo.fulfill()
                    return .success
                },
            ]
        )
        
        _ = try await client
            .request(for: .get, to: url, expecting: [String].self)
            .validate(with: Validator { _, _, _ in
                validatorThree.fulfill()
                return .success
            })
            .validate(with: Validator { _, _, _ in
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
    
    func test_client_whereValidatorThrows_catchesExpectedError() async throws {
        let url = createMockUrl()
        let expectedError = MockError(id: 1)
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .success(data: data, response: createResponse(for: url, with: 200))
            ]),
            validators: [
                Validator { _, _, _ in
                    .failure(expectedError)
                }
            ]
        )
        
        do {
            _ = try await client
                .request(for: .get, to: url, expecting: [String].self)
                .run()
        } catch {
            XCTAssertEqual(error as? MockError, expectedError)
        }
    }
    
    func test_request_whereValidatorThrows_catchesExpectedError() async throws {
        let url = createMockUrl()
        let expectedError = MockError(id: 1)
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .success(data: data, response: createResponse(for: url, with: 200))
            ])
        )
        
        do {
            _ = try await client
                .request(for: .get, to: url, expecting: [String].self)
                .validate { _, _, _ in
                    .failure(expectedError)
                }
                .run()
        } catch {
            XCTAssertEqual(error as? MockError, expectedError)
        }
    }
    
    // MARK: Retrier Tests
    
    func test_client_withRetrier_runsRetrierOnRequestAndSuccessfullyRetries() async throws {
        let url = createMockUrl()
        let expectedError = URLError(.cannotConnectToHost)
        let requestFiredExpectation = expectation(description: "Expected request to be fired twice.")
        requestFiredExpectation.expectedFulfillmentCount = 2
        requestFiredExpectation.assertForOverFulfill = true
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
                }, onRecieveRequest: { _ in
                    requestFiredExpectation.fulfill()
                })
            ]),
            retriers: [
                Retrier { _, _, _, error, _ in
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
        
        await fulfillment(of: [retryExpectation, requestFiredExpectation])
    }
    
    func test_client_withRetrier_runsRetrierOnRequestAndConcedesToFailure() async throws {
        let url = createMockUrl()
        let expectedError = URLError(.cannotConnectToHost)
        let requestFiredExpectation = expectation(description: "Expected request to be fired once.")
        requestFiredExpectation.assertForOverFulfill = true
        let retryExpectation = expectation(description: "Expected retry to be called.")
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .failure(expectedError, onRecieveRequest: { _ in
                    requestFiredExpectation.fulfill()
                }),
            ]),
            retriers: [
                Retrier { _, _, _, error, _ in
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
        
        await fulfillment(of: [retryExpectation, requestFiredExpectation])
    }
    
    func test_client_withMultipleRetriersSuccessfulAndConceding_runsFirstRetrierOnRequestAndNotSecond() async throws {
        let url = createMockUrl()
        let expectedError = URLError(.cannotConnectToHost)
        let requestFiredExpectation = expectation(description: "Expected request to be fired twice.")
        requestFiredExpectation.expectedFulfillmentCount = 2
        requestFiredExpectation.assertForOverFulfill = true
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
                }, onRecieveRequest: { _ in
                    requestFiredExpectation.fulfill()
                })
            ]),
            retriers: [
                Retrier { _, _, _, error, _ in
                    XCTAssertEqual((error as? URLError)?.code, expectedError.code)
                    retryExpectation.fulfill()
                    shouldRequestFail = false
                    return .retry
                },
                Retrier { _, _, _, error, _ in
                    XCTFail("Second retrier should not have been called.")
                    return .concede
                }
            ]
        )
        
        _ = try await client
            .request(for: .get, to: url, expecting: [String].self)
            .run()
        
        await fulfillment(of: [retryExpectation, requestFiredExpectation])
    }
    
    func test_client_withMultipleRetriersConcedingAndSuccessful_runsBothRetriersOnRequest() async throws {
        let url = createMockUrl()
        let expectedError = URLError(.cannotConnectToHost)
        let requestFiredExpectation = expectation(description: "Expected request to be fired twice.")
        requestFiredExpectation.expectedFulfillmentCount = 2
        requestFiredExpectation.assertForOverFulfill = true
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
                }, onRecieveRequest: { _ in
                    requestFiredExpectation.fulfill()
                })
            ]),
            retriers: [
                Retrier { _, _, _, error, _ in
                    XCTAssertEqual((error as? URLError)?.code, expectedError.code)
                    retrierOneExpectation.fulfill()
                    return .concede
                },
                Retrier { _, _, _, error, _ in
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
        
        await fulfillment(of: [retrierOneExpectation, retrierTwoExpectation, requestFiredExpectation])
    }
    
    func test_request_withRetrier_runsRetrierOnRequestAndSuccessfullyRetries() async throws {
        let url = createMockUrl()
        let expectedError = URLError(.cannotConnectToHost)
        let requestFiredExpectation = expectation(description: "Expected request to be fired twice.")
        requestFiredExpectation.expectedFulfillmentCount = 2
        requestFiredExpectation.assertForOverFulfill = true
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
                }, onRecieveRequest: { _ in
                    requestFiredExpectation.fulfill()
                })
            ])
        )
        
        _ = try await client
            .request(for: .get, to: url, expecting: [String].self)
            .retry(with: Retrier { _, _, _, error, _ in
                XCTAssertEqual((error as? URLError)?.code, expectedError.code)
                retryExpectation.fulfill()
                shouldRequestFail = false
                return .retry
            })
            .run()
        
        await fulfillment(of: [retryExpectation, requestFiredExpectation])
    }
    
    func test_request_withRetrier_runsRetrierOnRequestAndConcedesToFailure() async throws {
        let url = createMockUrl()
        let expectedError = URLError(.cannotConnectToHost)
        let requestFiredExpectation = expectation(description: "Expected request to be fired once.")
        requestFiredExpectation.assertForOverFulfill = true
        let retryExpectation = expectation(description: "Expected retry to be called.")
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .failure(expectedError, onRecieveRequest: { _ in
                    requestFiredExpectation.fulfill()
                }),
            ])
        )
        
        do {
            _ = try await client
                .request(for: .get, to: url, expecting: [String].self)
                .retry(with: Retrier { _, _, _, error, _ in
                    XCTAssertEqual((error as? URLError)?.code, expectedError.code)
                    retryExpectation.fulfill()
                    return .concede
                })
                .run()
            XCTFail("Expected request to fail after retry conceded.")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, expectedError.code)
        }
        
        await fulfillment(of: [retryExpectation, requestFiredExpectation])
    }
    
    func test_request_withMultipleRetriersSuccessfulAndConceding_runsFirstRetrierOnRequestAndNotSecond() async throws {
        let url = createMockUrl()
        let expectedError = URLError(.cannotConnectToHost)
        let requestFiredExpectation = expectation(description: "Expected request to be fired twice.")
        requestFiredExpectation.expectedFulfillmentCount = 2
        requestFiredExpectation.assertForOverFulfill = true
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
                }, onRecieveRequest: { _ in
                    requestFiredExpectation.fulfill()
                })
            ])
        )
        
        _ = try await client
            .request(for: .get, to: url, expecting: [String].self)
            .retry(with: Retrier { _, _, _, error, _ in
                XCTAssertEqual((error as? URLError)?.code, expectedError.code)
                retryExpectation.fulfill()
                shouldRequestFail = false
                return .retry
            })
            .retry(with: Retrier { _, _, _, error, _ in
                XCTFail("Second retrier should not have been called.")
                return .concede
            })
            .run()
        
        await fulfillment(of: [retryExpectation, requestFiredExpectation])
    }
    
    func test_request_withMultipleRetriersConcedingAndSuccessful_runsBothRetriersOnRequest() async throws {
        let url = createMockUrl()
        let expectedError = URLError(.cannotConnectToHost)
        let requestFiredExpectation = expectation(description: "Expected request to be fired twice.")
        requestFiredExpectation.expectedFulfillmentCount = 2
        requestFiredExpectation.assertForOverFulfill = true
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
                }, onRecieveRequest: { _ in
                    requestFiredExpectation.fulfill()
                })
            ])
        )
        
        _ = try await client
            .request(for: .get, to: url, expecting: [String].self)
            .retry(with: Retrier { _, _, _, error, _ in
                XCTAssertEqual((error as? URLError)?.code, expectedError.code)
                retrierOneExpectation.fulfill()
                return .concede
            })
            .retry(with: Retrier { _, _, _, error, _ in
                XCTAssertEqual((error as? URLError)?.code, expectedError.code)
                retrierTwoExpectation.fulfill()
                shouldRequestFail = false
                return .retry
            })
            .run()
        
        await fulfillment(of: [retrierOneExpectation, retrierTwoExpectation, requestFiredExpectation])
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
                Retrier { _, _, _, error, _ in
                    retrierOneExpectation.fulfill()
                    return .concede
                },
                Retrier { _, _, _, error, _ in
                    retrierTwoExpectation.fulfill()
                    return .concede
                }
            ]
        )
        
        do {
            _ = try await client
                .request(for: .get, to: url, expecting: [String].self)
                .retry(with: Retrier { _, _, _, error, _ in
                    retrierThreeExpectation.fulfill()
                    return .concede
                })
                .retry(with: Retrier { _, _, _, error, _ in
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
    
    func test_client_withDelayedRetry_doesRetryRequest() async throws {
        let url = createMockUrl()
        let expectedError = URLError(.cannotConnectToHost)
        let requestFiredExpectation = expectation(description: "Expected request to be fired twice.")
        requestFiredExpectation.expectedFulfillmentCount = 2
        requestFiredExpectation.assertForOverFulfill = true
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
                }, onRecieveRequest: { _ in
                    requestFiredExpectation.fulfill()
                })
            ]),
            retriers: [
                Retrier { _, _, _, error, _ in
                    XCTAssertEqual((error as? URLError)?.code, expectedError.code)
                    retryExpectation.fulfill()
                    shouldRequestFail = false
                    return .retryAfterDelay(.nanoseconds(100))
                }
            ]
        )
        
        _ = try await client
            .request(for: .get, to: url, expecting: [String].self)
            .run()
        
        await fulfillment(of: [retryExpectation, requestFiredExpectation])
    }
    
    func test_request_withDelayedRetry_doesRetryRequest() async throws {
        let url = createMockUrl()
        let expectedError = URLError(.cannotConnectToHost)
        let requestFiredExpectation = expectation(description: "Expected request to be fired twice.")
        requestFiredExpectation.expectedFulfillmentCount = 2
        requestFiredExpectation.assertForOverFulfill = true
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
                }, onRecieveRequest: { _ in
                    requestFiredExpectation.fulfill()
                })
            ])
        )
        
        _ = try await client
            .request(for: .get, to: url, expecting: [String].self)
            .retry { _, _, _, error, _ in
                XCTAssertEqual((error as? URLError)?.code, expectedError.code)
                retryExpectation.fulfill()
                shouldRequestFail = false
                return .retryAfterDelay(.nanoseconds(100))
            }
            .run()
        
        await fulfillment(of: [retryExpectation, requestFiredExpectation])
    }
    
    func test_request_withMultipleRetriers_doesCorrectlyIncrementPreviousAttempts() async throws {
        let url = createMockUrl()
        let retrierOneExpectation = expectation(description: "Expected retrier one to retry.")
        let retrierTwoExpectation = expectation(description: "Expected retrier two to retry.")
        let retrierThreeExpectation = expectation(description: "Expected retrier three to retry.")
        let retrierFourExpectation = expectation(description: "Expected retrier four to retry.")
        
        let block: (Int, Int, XCTestExpectation) -> RetryDecision = { previousAttempts, expectedPreviousAttempts, expectation in
            if previousAttempts == expectedPreviousAttempts {
                expectation.fulfill()
                return .retry
            } else {
                return .concede
            }
        }
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .failure(URLError(.cannotConnectToHost))
            ]),
            retriers: [
                Retrier {
                    block($4, 1, retrierOneExpectation)
                },
                Retrier { block($4, 2, retrierTwoExpectation) },
            ]
        )
        
        do {
            _ = try await client
                .request(for: .get, to: url, expecting: [String].self)
                .retry { block($4, 3, retrierThreeExpectation) }
                .retry { block($4, 4, retrierFourExpectation) }
                .run()
            XCTFail("Expected request to fail.")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .cannotConnectToHost)
        }
        
        await fulfillment(of: [retrierOneExpectation, retrierTwoExpectation, retrierThreeExpectation, retrierFourExpectation], enforceOrder: true)
    }
    
    func test_client_whereRetrierThrows_catchesExpectedError() async throws {
        let url = createMockUrl()
        let expectedError = MockError(id: 1)
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .success(data: data, response: createResponse(for: url, with: 200))
            ]),
            retriers: [
                Retrier { _, _, _, _, _ in
                    throw expectedError
                }
            ]
        )
        
        do {
            _ = try await client
                .request(for: .get, to: url, expecting: [String].self)
                .run()
        } catch {
            XCTAssertEqual(error as? MockError, expectedError)
        }
    }
    
    func test_request_whereRetrierThrows_catchesExpectedError() async throws {
        let url = createMockUrl()
        let expectedError = MockError(id: 1)
        
        let client = HTTPClient(
            dispatcher: .mock(responses: [
                url: .success(data: data, response: createResponse(for: url, with: 200))
            ])
        )
        
        do {
            _ = try await client
                .request(for: .get, to: url, expecting: [String].self)
                .retry { _, _, _, _, _ in
                    throw expectedError
                }
                .run()
        } catch {
            XCTAssertEqual(error as? MockError, expectedError)
        }
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
            validators: [
                Validator { _, _, _ in
                    XCTFail("Validator should not have been called after task cancellation.")
                    return .success
                }
            ],
            retriers: [
                Retrier { _, _, _, _, _ in
                    XCTFail("Retrier should not have been called after task cancellation.")
                    return .concede
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
            validators: [
                Validator { _, _, _ in
                    task?.cancel()
                    return .success
                },
                Validator { _, _, _ in
                    XCTFail("Second validator should not have been called after task cancellation.")
                    return .success
                }
            ],
            retriers: [
                Retrier { _, _, _, _, _ in
                    XCTFail("Retrier should not have been called after task cancellation.")
                    return .concede
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
                Retrier { _, _, _, _, _ in
                    task?.cancel()
                    return .concede
                },
                Retrier { _, _, _, _, _ in
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
