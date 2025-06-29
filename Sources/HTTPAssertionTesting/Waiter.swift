import Foundation
import XCTest
import HTTPAssertionLogging

/// Errors that can occur during context wait operations
public enum ContextWaitError: Error, LocalizedError {
    case invalidStoragePath(key: String)
    case retrievalFailed(key: String)
    case timeout(key: String, timeout: TimeInterval)
    
    public var errorDescription: String? {
        switch self {
        case .invalidStoragePath(let key):
            return "Could not determine storage path for context key: \(key)"
        case .retrievalFailed(let key):
            return "Failed to retrieve context value for key: \(key)"
        case .timeout(let key, let timeout):
            return "Context update timed out after \(timeout)s for key: \(key)"
        }
    }
}

/// XCTestCase extensions for HTTP assertion wait methods
public extension XCTestCase {
    
    // MARK: - HTTP Request Wait Methods
    
    /// Waits for a request matching the given criteria to receive a response
    func waitForResponse(
        url: String? = nil,
        urlPattern: String? = nil,
        method: String? = nil,
        headers: [String: String]? = nil,
        queryParameters: [String: String]? = nil,
        since: Date? = Date().addingTimeInterval(-30.0),
        timeout: TimeInterval = 10.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async -> HTTPRequests.HTTPRequest? {
        let matcher = HTTPRequestMatcher(
            url: url,
            urlPattern: urlPattern,
            method: method,
            headers: headers,
            queryParameters: queryParameters
        )
        
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ -> Bool in
                // Use HTTPRequests static methods directly
                let semaphore = DispatchSemaphore(value: 0)
                var foundRequest: HTTPRequests.HTTPRequest? = nil
                Task.detached {
                    let requests = await HTTPRequests.recentRequests(sortBy: .requestTime, since: since)
                    foundRequest = requests.first { matcher.matches($0) && $0.response != nil }
                    semaphore.signal()
                }
                semaphore.wait()
                return foundRequest != nil
            },
            object: nil
        )
        
        let result = await XCTWaiter.fulfillment(of: [expectation], timeout: timeout)
        
        if result == .completed {
            let requests = await HTTPRequests.recentRequests(sortBy: .requestTime, since: since)
            return requests.first { matcher.matches($0) && $0.response != nil }
        } else {
            XCTFail(
                "Request matching criteria did not receive response within timeout: \(matcher.description)",
                file: file,
                line: line
            )
            return nil
        }
    }
    
    /// Waits for a specific recorded request to receive a response
    func waitForResponse(
        for recordedRequest: HTTPRequests.HTTPRequest,
        since: Date? = Date().addingTimeInterval(-30.0),
        timeout: TimeInterval = 10.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async -> HTTPRequests.HTTPRequest? {
        let requestID = recordedRequest.id
        
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ -> Bool in
                // Use HTTPRequests static methods directly
                let semaphore = DispatchSemaphore(value: 0)
                var foundRequest: HTTPRequests.HTTPRequest? = nil
                Task.detached {
                    let requests = await HTTPRequests.recentRequests(sortBy: .requestTime, since: since)
                    foundRequest = requests.first { $0.id == requestID && $0.response != nil }
                    semaphore.signal()
                }
                semaphore.wait()
                return foundRequest != nil
            },
            object: nil
        )
        
        let result = await XCTWaiter.fulfillment(of: [expectation], timeout: timeout)
        
        if result == .completed {
            let requests = await HTTPRequests.recentRequests(sortBy: .requestTime, since: since)
            return requests.first { $0.id == requestID && $0.response != nil }
        } else {
            XCTFail(
                "Request with ID \(requestID) did not receive response within timeout",
                file: file,
                line: line
            )
            return nil
        }
    }
    
    /// Waits for a request matching the given criteria to be fired, regardless of response status
    func waitForRequest(
        url: String? = nil,
        urlPattern: String? = nil,
        method: String? = nil,
        headers: [String: String]? = nil,
        queryParameters: [String: String]? = nil,
        since: Date? = Date().addingTimeInterval(-30.0),
        timeout: TimeInterval = 10.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async -> HTTPRequests.HTTPRequest? {
        let matcher = HTTPRequestMatcher(
            url: url,
            urlPattern: urlPattern,
            method: method,
            headers: headers,
            queryParameters: queryParameters
        )
        
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ -> Bool in
                // Use HTTPRequests static methods directly
                let semaphore = DispatchSemaphore(value: 0)
                var foundRequest: HTTPRequests.HTTPRequest? = nil
                Task.detached {
                    let requests = await HTTPRequests.recentRequests(sortBy: .requestTime, since: since)
                    foundRequest = requests.first { matcher.matches($0) }
                    semaphore.signal()
                }
                semaphore.wait()
                return foundRequest != nil
            },
            object: nil
        )
        
        let result = await XCTWaiter.fulfillment(of: [expectation], timeout: timeout)
        
        if result == .completed {
            let requests = await HTTPRequests.recentRequests(sortBy: .requestTime, since: since)
            return requests.first { matcher.matches($0) }
        } else {
            XCTFail(
                "Request matching criteria was not fired within timeout: \(matcher.description)",
                file: file,
                line: line
            )
            return nil
        }
    }
    
    // MARK: - Context Wait Methods
    
    /// Waits for a context value to be updated or become available
    func waitForContextUpdate<T: Codable & Sendable>(
        forKey key: String,
        since: Date = Date.now,
        timeout: TimeInterval = 10.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> T {
        // Get the context file URL using FileStorage
        guard let fileURL = await Context.storage.fileURL(forKey: key) else {
            XCTFail("Could not determine context file path", file: file, line: line)
            throw ContextWaitError.invalidStoragePath(key: key)
        }
        
        let filePath = fileURL.path
        
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ -> Bool in
                let semaphore = DispatchSemaphore(value: 0)
                var fileWasUpdated = false
                
                Task.detached {
                    let fm = FileManager.default
                    // Check if file exists and get its current modification date
                    if fm.fileExists(atPath: filePath),
                       let attributes = try? fm.attributesOfItem(atPath: filePath),
                       let currentModificationDate = attributes[.modificationDate] as? Date {
                        
                        // Check if file was modified after the since date
                        fileWasUpdated = currentModificationDate > since
                    }
                    semaphore.signal()
                }
                semaphore.wait()
                return fileWasUpdated
            },
            object: nil
        )
        
        let result = await XCTWaiter.fulfillment(of: [expectation], timeout: timeout)
        
        if result == .completed {
            if let value = try await Context.retrieve(T.self, forKey: key) {
                return value
            } else {
                XCTFail(
                    "Context value for key '\(key)' exists but could not be retrieved",
                    file: file,
                    line: line
                )
                throw ContextWaitError.retrievalFailed(key: key)
            }
        } else {
            XCTFail(
                "Context value for key '\(key)' was not updated within timeout",
                file: file,
                line: line
            )
            throw ContextWaitError.timeout(key: key, timeout: timeout)
        }
    }
}
