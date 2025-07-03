import XCTest
import Foundation
@testable import HTTPAssertionTesting
@testable import HTTPAssertionLogging

final class HostRelativePathTests: XCTestCase {
    
    func testHTTPRequestMatcherWithHost() {
        let url = URL(string: "https://api.example.com/v1/users")!
        let request = URLRequest(url: url)
        let httpRequest = HTTPRequests.HTTPRequest(
            id: UUID().uuidString,
            timestamp: Date(),
            request: request,
            response: nil,
            responseData: nil,
            error: nil
        )
        
        // Test host matching
        let hostMatcher = HTTPRequestMatcher(
            url: nil,
            urlPattern: nil,
            host: "api.example.com",
            relativePath: nil,
            method: nil,
            headers: nil,
            queryParameters: nil
        )
        
        XCTAssertTrue(hostMatcher.matches(httpRequest))
        
        // Test host non-matching
        let nonMatchingHostMatcher = HTTPRequestMatcher(
            url: nil,
            urlPattern: nil,
            host: "api.different.com",
            relativePath: nil,
            method: nil,
            headers: nil,
            queryParameters: nil
        )
        
        XCTAssertFalse(nonMatchingHostMatcher.matches(httpRequest))
    }
    
    func testHTTPRequestMatcherWithRelativePath() {
        let url = URL(string: "https://api.example.com/v1/users")!
        let request = URLRequest(url: url)
        let httpRequest = HTTPRequests.HTTPRequest(
            id: UUID().uuidString,
            timestamp: Date(),
            request: request,
            response: nil,
            responseData: nil,
            error: nil
        )
        
        // Test relative path matching
        let pathMatcher = HTTPRequestMatcher(
            url: nil,
            urlPattern: nil,
            host: nil,
            relativePath: "/v1/users",
            method: nil,
            headers: nil,
            queryParameters: nil
        )
        
        XCTAssertTrue(pathMatcher.matches(httpRequest))
        
        // Test relative path non-matching
        let nonMatchingPathMatcher = HTTPRequestMatcher(
            url: nil,
            urlPattern: nil,
            host: nil,
            relativePath: "/v1/products",
            method: nil,
            headers: nil,
            queryParameters: nil
        )
        
        XCTAssertFalse(nonMatchingPathMatcher.matches(httpRequest))
    }
    
    func testHTTPRequestMatcherWithHostAndRelativePath() {
        let url = URL(string: "https://api.example.com/v1/users")!
        let request = URLRequest(url: url)
        let httpRequest = HTTPRequests.HTTPRequest(
            id: UUID().uuidString,
            timestamp: Date(),
            request: request,
            response: nil,
            responseData: nil,
            error: nil
        )
        
        // Test both host and relative path matching
        let combinedMatcher = HTTPRequestMatcher(
            url: nil,
            urlPattern: nil,
            host: "api.example.com",
            relativePath: "/v1/users",
            method: nil,
            headers: nil,
            queryParameters: nil
        )
        
        XCTAssertTrue(combinedMatcher.matches(httpRequest))
        
        // Test host matching but path not matching
        let hostOnlyMatcher = HTTPRequestMatcher(
            url: nil,
            urlPattern: nil,
            host: "api.example.com",
            relativePath: "/v1/products",
            method: nil,
            headers: nil,
            queryParameters: nil
        )
        
        XCTAssertFalse(hostOnlyMatcher.matches(httpRequest))
        
        // Test path matching but host not matching
        let pathOnlyMatcher = HTTPRequestMatcher(
            url: nil,
            urlPattern: nil,
            host: "api.different.com",
            relativePath: "/v1/users",
            method: nil,
            headers: nil,
            queryParameters: nil
        )
        
        XCTAssertFalse(pathOnlyMatcher.matches(httpRequest))
    }
    
    func testHTTPRequestMatcherWithComplexURL() {
        let url = URL(string: "https://api.example.com:8080/v1/users/123?sort=name&limit=10#section")!
        let request = URLRequest(url: url)
        let httpRequest = HTTPRequests.HTTPRequest(
            id: UUID().uuidString,
            timestamp: Date(),
            request: request,
            response: nil,
            responseData: nil,
            error: nil
        )
        
        // Test host matching with port (host should not include port)
        let hostMatcher = HTTPRequestMatcher(
            url: nil,
            urlPattern: nil,
            host: "api.example.com",
            relativePath: nil,
            method: nil,
            headers: nil,
            queryParameters: nil
        )
        
        XCTAssertTrue(hostMatcher.matches(httpRequest))
        
        // Test path matching with query params and fragment (path should not include query/fragment)
        let pathMatcher = HTTPRequestMatcher(
            url: nil,
            urlPattern: nil,
            host: nil,
            relativePath: "/v1/users/123",
            method: nil,
            headers: nil,
            queryParameters: nil
        )
        
        XCTAssertTrue(pathMatcher.matches(httpRequest))
        
        // Test combined matching
        let combinedMatcher = HTTPRequestMatcher(
            url: nil,
            urlPattern: nil,
            host: "api.example.com",
            relativePath: "/v1/users/123",
            method: nil,
            headers: nil,
            queryParameters: nil
        )
        
        XCTAssertTrue(combinedMatcher.matches(httpRequest))
    }
    
    func testHTTPRequestMatcherDescription() {
        let matcher = HTTPRequestMatcher(
            url: nil,
            urlPattern: nil,
            host: "api.example.com",
            relativePath: "/v1/users",
            method: "GET",
            headers: ["Authorization": "Bearer token"],
            queryParameters: ["limit": "10"]
        )
        
        let description = matcher.description
        XCTAssertTrue(description.contains("host=api.example.com"))
        XCTAssertTrue(description.contains("relativePath=/v1/users"))
        XCTAssertTrue(description.contains("method=GET"))
        XCTAssertTrue(description.contains("headers="))
        XCTAssertTrue(description.contains("queryParameters="))
    }
    
    func testHTTPRequestMatcherWithEmptyPath() {
        let url = URL(string: "https://api.example.com/")!
        let request = URLRequest(url: url)
        let httpRequest = HTTPRequests.HTTPRequest(
            id: UUID().uuidString,
            timestamp: Date(),
            request: request,
            response: nil,
            responseData: nil,
            error: nil
        )
        
        // Test matching root path
        let rootPathMatcher = HTTPRequestMatcher(
            url: nil,
            urlPattern: nil,
            host: nil,
            relativePath: "/",
            method: nil,
            headers: nil,
            queryParameters: nil
        )
        
        XCTAssertTrue(rootPathMatcher.matches(httpRequest))
    }
    
    func testHTTPRequestMatcherWithNoPath() {
        let url = URL(string: "https://api.example.com")!
        let request = URLRequest(url: url)
        let httpRequest = HTTPRequests.HTTPRequest(
            id: UUID().uuidString,
            timestamp: Date(),
            request: request,
            response: nil,
            responseData: nil,
            error: nil
        )
        
        // Test matching empty path (URL without trailing slash)
        let emptyPathMatcher = HTTPRequestMatcher(
            url: nil,
            urlPattern: nil,
            host: nil,
            relativePath: "",
            method: nil,
            headers: nil,
            queryParameters: nil
        )
        
        XCTAssertTrue(emptyPathMatcher.matches(httpRequest))
    }
}