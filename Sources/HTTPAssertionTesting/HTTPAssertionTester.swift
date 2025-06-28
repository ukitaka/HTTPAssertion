import Foundation
import XCTest
import HTTPAssertionLogging

/// Provides assertion APIs for XCUITest to verify HTTP requests
public final class HTTPAssertionTester {
    
    private let storage = HTTPRequestStorage.shared
    
    public init() {
        // Storage is already initialized by HTTPAssertionLogging
    }
    
    /// Asserts that a request matching the given criteria exists
    public func assertRequest(
        url: String? = nil,
        urlPattern: String? = nil,
        method: String? = nil,
        headers: [String: String]? = nil,
        queryParameters: [String: String]? = nil,
        timeout: TimeInterval = 5.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let matcher = HTTPRequestMatcher(
            url: url,
            urlPattern: urlPattern,
            method: method,
            headers: headers,
            queryParameters: queryParameters
        )
        
        let deadline = Date().addingTimeInterval(timeout)
        var found = false
        
        while Date() < deadline && !found {
            let requests = storage.loadRequestsFromDisk()
            found = requests.contains { matcher.matches($0) }
            
            if !found {
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
        
        XCTAssertTrue(
            found,
            "No HTTP request found matching criteria: \(matcher.description)",
            file: (file),
            line: line
        )
    }
    
    /// Asserts that no request matching the given criteria exists
    public func assertNoRequest(
        url: String? = nil,
        urlPattern: String? = nil,
        method: String? = nil,
        headers: [String: String]? = nil,
        queryParameters: [String: String]? = nil,
        timeout: TimeInterval = 2.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let matcher = HTTPRequestMatcher(
            url: url,
            urlPattern: urlPattern,
            method: method,
            headers: headers,
            queryParameters: queryParameters
        )
        
        Thread.sleep(forTimeInterval: timeout)
        
        let requests = storage.loadRequestsFromDisk()
        let found = requests.contains { matcher.matches($0) }
        
        XCTAssertFalse(
            found,
            "Unexpected HTTP request found matching criteria: \(matcher.description)",
            file: (file),
            line: line
        )
    }
    
    /// Gets all requests matching the given criteria
    public func requests(
        url: String? = nil,
        urlPattern: String? = nil,
        method: String? = nil,
        headers: [String: String]? = nil,
        queryParameters: [String: String]? = nil
    ) -> [RecordedHTTPRequest] {
        let matcher = HTTPRequestMatcher(
            url: url,
            urlPattern: urlPattern,
            method: method,
            headers: headers,
            queryParameters: queryParameters
        )
        
        let requests = storage.loadRequestsFromDisk()
        return requests.filter { matcher.matches($0) }
    }
    
    /// Clears all recorded requests (useful for test cleanup)
    public func clearAllRequests() {
        storage.clear()
    }
}

/// Matches HTTP requests based on various criteria
private struct HTTPRequestMatcher {
    let url: String?
    let urlPattern: String?
    let method: String?
    let headers: [String: String]?
    let queryParameters: [String: String]?
    
    var description: String {
        var parts: [String] = []
        if let url = url { parts.append("url=\(url)") }
        if let urlPattern = urlPattern { parts.append("urlPattern=\(urlPattern)") }
        if let method = method { parts.append("method=\(method)") }
        if let headers = headers { parts.append("headers=\(headers)") }
        if let queryParameters = queryParameters { parts.append("queryParameters=\(queryParameters)") }
        return parts.joined(separator: ", ")
    }
    
    func matches(_ request: RecordedHTTPRequest) -> Bool {
        // Check URL
        if let url = url {
            guard request.request.url?.absoluteString == url else { return false }
        }
        
        // Check URL pattern
        if let urlPattern = urlPattern {
            guard let requestURL = request.request.url?.absoluteString,
                  requestURL.range(of: urlPattern, options: .regularExpression) != nil else {
                return false
            }
        }
        
        // Check method
        if let method = method {
            guard request.request.httpMethod?.uppercased() == method.uppercased() else { return false }
        }
        
        // Check headers
        if let headers = headers {
            guard let requestHeaders = request.request.allHTTPHeaderFields else { return false }
            for (key, value) in headers {
                guard requestHeaders[key] == value else { return false }
            }
        }
        
        // Check query parameters
        if let queryParameters = queryParameters {
            guard let components = request.request.url.flatMap({ URLComponents(url: $0, resolvingAgainstBaseURL: false) }),
                  let queryItems = components.queryItems else {
                return false
            }
            
            for (key, value) in queryParameters {
                guard queryItems.contains(where: { $0.name == key && $0.value == value }) else {
                    return false
                }
            }
        }
        
        return true
    }
}