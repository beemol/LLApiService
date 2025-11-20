//
//  APIService.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 18/11/2025.
//

import Foundation

public enum LLAPIError: Error, Equatable {
    case invalidRequest
    case httpError(HTTPURLResponse)
}

@available(iOS 13.0.0, macOS 10.15, *)
public class LLApiService<Output> {
    private let requestBuilder: LLAPIRequestBuilder
    private let networkService: LLNetworkServiceProtocol
    
    private let errorDetector: LLDomainErrorDetector?
    private let analyticsTracker: LLAnalyticsTracker?
    
    // closure to use LLResponseParserProtocol parsing logic
    private var parseClosure: (Data) throws -> Output
    
    public init<P: LLResponseParserProtocol>(requestBuilder: LLAPIRequestBuilder,
                                      networkService: LLNetworkServiceProtocol,
                                      errorDetector: LLDomainErrorDetector? = nil,
                                      analyticsTracker: LLAnalyticsTracker? = nil,
                                      parser: P) where P.Output == Output {
        self.requestBuilder = requestBuilder
        self.networkService = networkService
        self.errorDetector = errorDetector
        self.analyticsTracker = analyticsTracker
        self.parseClosure = parser.parse
    }
    
    public func execute() async throws -> Output {

        let request = try requestBuilder.createRequest()
        
        // 2. Execute network call
        let (data, response) = try await networkService.send(request: request)
        
        // 3. Check HTTP status code
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            throw LLAPIError.httpError(httpResponse)
        }
        
        // 4. Check for application-level errors (even with HTTP 200)
        try errorDetector?.detectError(data: data, response: response)

        // 5. Parse response
        return try self.parseClosure(data)
    }
}
