import Foundation
import XCTest
import HTTPAssertion

/// Provides assertion APIs for XCUITest to verify HTTP requests
public final class HTTPAssertionTester {
    
    private let storage: HTTPRequestReader
    
    public init() {
        self.storage = HTTPRequestReader()
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
            let requests = storage.loadAllRequests()
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
        
        let requests = storage.loadAllRequests()
        let found = requests.contains { matcher.matches($0) }
        
        XCTAssertFalse(
            found,
            "Unexpected HTTP request found matching criteria: \(matcher.description)",
            file: (file),
            line: line
        )
    }
    
    /// Gets all requests matching the given criteria
    public func getRequests(
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
        
        let requests = storage.loadAllRequests()
        return requests.filter { matcher.matches($0) }
    }
    
    /// Clears all recorded requests (useful for test cleanup)
    public func clearAllRequests() {
        storage.clearAll()
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

/// Reads HTTP requests from the shared storage directory
private final class HTTPRequestReader {
    private let fileManager = FileManager.default
    private let decoder = JSONDecoder()
    
    private var storageDirectory: URL? {
        #if targetEnvironment(simulator)
        // Use SIMULATOR_SHARED_RESOURCES_DIRECTORY for simulator
        if let sharedDir = ProcessInfo.processInfo.environment["SIMULATOR_SHARED_RESOURCES_DIRECTORY"] {
            let url = URL(fileURLWithPath: sharedDir)
                .appendingPathComponent("Library")
                .appendingPathComponent("Caches")
                .appendingPathComponent("HTTPAssertion")
            return url
        }
        #endif
        
        // Fallback to app's caches directory
        return fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("HTTPAssertion")
    }
    
    init() {
        decoder.dateDecodingStrategy = .iso8601
    }
    
    func loadAllRequests() -> [RecordedHTTPRequest] {
        guard let directory = storageDirectory else { return [] }
        
        var requests: [RecordedHTTPRequest] = []
        
        do {
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            
            for file in files where file.pathExtension == "json" {
                do {
                    let data = try Data(contentsOf: file)
                    let request = try decoder.decode(RecordedHTTPRequest.self, from: data)
                    requests.append(request)
                } catch {
                    // Skip corrupted files
                    continue
                }
            }
        } catch {
            // Directory might not exist yet
            return []
        }
        
        return requests.sorted { $0.timestamp < $1.timestamp }
    }
    
    func clearAll() {
        guard let directory = storageDirectory else { return }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            for file in files where file.pathExtension == "json" {
                try fileManager.removeItem(at: file)
            }
        } catch {
            // Ignore errors during cleanup
        }
    }
}