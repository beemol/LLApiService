//
//  Protocols.swift
//  LLApiService
//
//  Created by Aleh Fiodarau on 19/11/2025.
//

import Foundation

@available(iOS 13.0.0, macOS 10.15, *)
public protocol URLSessionProtocol: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

@available(iOS 13.0.0, macOS 10.15, *)
extension URLSession: URLSessionProtocol {}

@available(iOS 13.0.0, macOS 10.15, *)
public protocol LLNetworkServiceProtocol {
    func send(request: URLRequest) async throws -> (Data, URLResponse)
}

// MARK: - Default Network Service Implementation
@available(iOS 13.0.0, macOS 10.15, *)
public class LLNetworkService: LLNetworkServiceProtocol {
    private let urlSession: URLSessionProtocol
    
    public init(urlSession: URLSessionProtocol = URLSession.shared) {
        self.urlSession = urlSession
    }
    
    public func send(request: URLRequest) async throws -> (Data, URLResponse) {
        try await urlSession.data(for: request)
    }
}

public protocol LLAPIRequestBuilder {
    func createRequest() throws -> URLRequest
}

// MARK: - Domain error detector (optionally injected by client app)
public protocol LLDomainErrorDetector {
    /// - Throws: Domain-specific error if detected
    /// - Returns: Silently if no error found
    func detectError(data: Data, response: URLResponse) throws
}

public protocol LLAnalyticsTracker {
    func log(_ message: [String: String])
}

// MARK: - Response Parsing (injected by client app)
public protocol LLResponseParserProtocol {
    associatedtype Output
    
    func parse(data: Data) throws -> Output
}
