import Testing
import Foundation

@testable import LLApiService

struct LLApiServiceTests {

    @Test
    func given_badRequestDataa_and_badNetwork_expect_toStop_withInvalidRequest() async throws {
        let service = LLApiService(requestBuilder: MockLLAPIRequestBuilder(shouldThrow: true),
                                   networkService: MockNetworkService(shouldThrow: true),
                                   parser: MockParser())
        
        let error = await #expect(throws: LLAPIError.self) {
            try await service.execute()
        }
        
        #expect(error == LLAPIError.invalidRequest)
    }
    
    @Test
    func given_goodRequestData_and_badNetwork_expect_toStop_withNetworkError() async throws {
        let service = LLApiService(requestBuilder: MockLLAPIRequestBuilder(shouldThrow: false),
                                   networkService: MockNetworkService(shouldThrow: true),
                                   parser: MockParser())
        
        let error = await #expect(throws: LLAPIError.self) {
            try await service.execute()
        }
        
        if case .httpError = error {
            // Success: error is httpError
        } else {
            Issue.record("Expected httpError but got \(error)")
        }
    }
    
    @Test
    func given_goodRequestData_and_goodNetwork_expect_successfulExecution() async throws {
        let service = LLApiService(requestBuilder: MockLLAPIRequestBuilder(shouldThrow: false),
                                   networkService: MockNetworkService(shouldThrow: false),
                                   parser: MockParser())
        
        let result = try await service.execute()
        
        #expect(result == MockParser.expectedSuccess)
    }
    
    @Test
    func given_goodRequestData_and_domainError_expect_toStop_withDomainError() async throws {
        let errorDetector = MockLLDomainErrorDetector()
        errorDetector.shouldDetectError = true
        
        let service = LLApiService(requestBuilder: MockLLAPIRequestBuilder(shouldThrow: false),
                                   networkService: MockNetworkService(shouldThrow: false),
                                   errorDetector: errorDetector,
                                   parser: MockParser())
        
        await #expect(throws: Error.self) {
            try await service.execute()
        }
    }
    
    @Test
    func given_goodRequestData_and_parserError_expect_toStop_withParserError() async throws {
        let service = LLApiService(requestBuilder: MockLLAPIRequestBuilder(shouldThrow: false),
                                   networkService: MockNetworkService(shouldThrow: false),
                                   parser: MockParser(shouldThrow: true))
        
        await #expect(throws: Error.self) {
            try await service.execute()
        }
    }
    
    @Test
    func given_httpErrorWithStatusCode_expect_httpErrorWithResponse() async throws {
        let url = URL(string: "https://test.com")!
        let httpResponse = HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)!
        
        let service = LLApiService(requestBuilder: MockLLAPIRequestBuilder(shouldThrow: false),
                                   networkService: MockNetworkService(httpResponse: httpResponse),
                                   parser: MockParser())
        
        let error = await #expect(throws: LLAPIError.self) {
            try await service.execute()
        }
        
        if case .httpError(let response) = error {
            #expect(response.statusCode == 404)
        } else {
            Issue.record("Expected httpError but got \(error)")
        }
    }
}


// Mocks
class MockNetworkService: LLNetworkServiceProtocol {
    let shouldThrow: Bool
    let httpResponse: HTTPURLResponse?
    
    init(shouldThrow: Bool) {
        self.shouldThrow = shouldThrow
        self.httpResponse = nil
    }
    
    init(httpResponse: HTTPURLResponse) {
        self.shouldThrow = false
        self.httpResponse = httpResponse
    }
    
    func send(request: URLRequest) async throws -> (Data, URLResponse) {
        guard !shouldThrow else { throw LLAPIError.httpError(HTTPURLResponse()) }
        
        if let httpResponse = httpResponse {
            return (Data(), httpResponse)
        }
        
        let url = URL(string: "https://test.com")!
        let successResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (Data(), successResponse)
    }
}

class MockLLAPIRequestBuilder: LLAPIRequestBuilder {
    let shouldThrow: Bool
    
    init(shouldThrow: Bool) {
        self.shouldThrow = shouldThrow
    }
    
    func createRequest() throws -> URLRequest {
        guard !shouldThrow else { throw LLAPIError.invalidRequest }
        
        let url = URL(string: "https://test.com")!
        return URLRequest(url: url)
    }
}

class MockLLDomainErrorDetector: LLDomainErrorDetector {
    var shouldDetectError: Bool = false
    
    func detectError(data: Data, response: URLResponse) throws {
        if shouldDetectError { throw NSError(domain: "", code: 0, userInfo: nil) }
    }
}

class MockParser: LLResponseParserProtocol {
    typealias Output = String
    let shouldThrow: Bool
    static let expectedSuccess = "Test"
    
    init(shouldThrow: Bool = false) {
        self.shouldThrow = shouldThrow
    }
    
    func parse(data: Data) throws -> Output {
        if shouldThrow {
            throw NSError(domain: "ParserError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Parse failed"])
        }
        return MockParser.expectedSuccess
    }
}

class MockAnalyticsTracker: LLAnalyticsTracker {
    var loggedMessages: [[String: String]] = []
    
    func log(_ message: [String: String]) {
        loggedMessages.append(message)
    }
}
