import XCTest
@testable import HTTPAssertionLogging
@testable import HTTPAssertionTesting

final class HeaderTests: XCTestCase {
    
    override func tearDown() {
        HTTPAssertionLogging.stop()
        super.tearDown()
    }
    
    func testHTTPAssertHeader() throws {
        // Create a request with headers
        let url = URL(string: "https://api.example.com/data")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer token123", forHTTPHeaderField: "Authorization")
        request.setValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
        
        let httpRequest = HTTPRequests.HTTPRequest(
            id: "test-1",
            timestamp: Date(),
            request: request,
            response: nil,
            responseData: nil,
            error: nil
        )
        
        // Test successful assertions
        HTTPAssertHeader(httpRequest, name: "Content-Type", value: "application/json")
        HTTPAssertHeader(httpRequest, name: "Authorization", value: "Bearer token123")
        HTTPAssertHeader(httpRequest, name: "Accept-Encoding", value: "gzip, deflate")
    }
    
    func testHTTPAssertHeaderCaseInsensitive() throws {
        let url = URL(string: "https://api.example.com/data")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer token123", forHTTPHeaderField: "Authorization")
        
        let httpRequest = HTTPRequests.HTTPRequest(
            id: "test-1",
            timestamp: Date(),
            request: request,
            response: nil,
            responseData: nil,
            error: nil
        )
        
        // Test case-insensitive header matching
        HTTPAssertHeader(httpRequest, name: "content-type", value: "application/json")
        HTTPAssertHeader(httpRequest, name: "CONTENT-TYPE", value: "application/json")
        HTTPAssertHeader(httpRequest, name: "authorization", value: "Bearer token123")
        HTTPAssertHeader(httpRequest, name: "AUTHORIZATION", value: "Bearer token123")
    }
    
    func testHTTPAssertHeaderExists() throws {
        let url = URL(string: "https://api.example.com/data")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("", forHTTPHeaderField: "X-Empty-Header")
        request.setValue("custom-value", forHTTPHeaderField: "X-Custom-Header")
        
        let httpRequest = HTTPRequests.HTTPRequest(
            id: "test-1",
            timestamp: Date(),
            request: request,
            response: nil,
            responseData: nil,
            error: nil
        )
        
        HTTPAssertHeaderExists(httpRequest, name: "Content-Type")
        HTTPAssertHeaderExists(httpRequest, name: "X-Empty-Header")
        HTTPAssertHeaderExists(httpRequest, name: "X-Custom-Header")
        
        // Test case-insensitive
        HTTPAssertHeaderExists(httpRequest, name: "content-type")
        HTTPAssertHeaderExists(httpRequest, name: "x-custom-header")
    }
    
    func testHTTPAssertHeaderNotExists() throws {
        let url = URL(string: "https://api.example.com/data")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let httpRequest = HTTPRequests.HTTPRequest(
            id: "test-1",
            timestamp: Date(),
            request: request,
            response: nil,
            responseData: nil,
            error: nil
        )
        
        HTTPAssertHeaderNotExists(httpRequest, name: "Authorization")
        HTTPAssertHeaderNotExists(httpRequest, name: "X-Custom-Header")
        HTTPAssertHeaderNotExists(httpRequest, name: "Accept")
        
        // Test case-insensitive
        HTTPAssertHeaderNotExists(httpRequest, name: "authorization")
        HTTPAssertHeaderNotExists(httpRequest, name: "AUTHORIZATION")
    }
    
    func testHTTPAssertHeaders() throws {
        let url = URL(string: "https://api.example.com/users")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer secret-token", forHTTPHeaderField: "Authorization")
        request.setValue("MyApp/1.0", forHTTPHeaderField: "User-Agent")
        
        let httpRequest = HTTPRequests.HTTPRequest(
            id: "test-1",
            timestamp: Date(),
            request: request,
            response: nil,
            responseData: nil,
            error: nil
        )
        
        let expectedHeaders = [
            "Content-Type": "application/json",
            "Authorization": "Bearer secret-token",
            "User-Agent": "MyApp/1.0"
        ]
        
        HTTPAssertHeaders(httpRequest, expectedHeaders)
    }
    
    func testHTTPAssertHeaderNotEqual() throws {
        let url = URL(string: "https://api.example.com/data")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer token123", forHTTPHeaderField: "Authorization")
        request.setValue("", forHTTPHeaderField: "X-Empty-Header")
        
        let httpRequest = HTTPRequests.HTTPRequest(
            id: "test-1",
            timestamp: Date(),
            request: request,
            response: nil,
            responseData: nil,
            error: nil
        )
        
        // Test that headers don't have wrong values
        HTTPAssertHeaderNotEqual(httpRequest, name: "Content-Type", value: "text/html")
        HTTPAssertHeaderNotEqual(httpRequest, name: "Authorization", value: "Bearer wrong-token")
        HTTPAssertHeaderNotEqual(httpRequest, name: "X-Empty-Header", value: "not empty")
        
        // Test that nonexistent headers don't have any value (should always pass)
        HTTPAssertHeaderNotEqual(httpRequest, name: "X-Nonexistent", value: "any value")
        
        // Test case-insensitive
        HTTPAssertHeaderNotEqual(httpRequest, name: "content-type", value: "text/plain")
        HTTPAssertHeaderNotEqual(httpRequest, name: "AUTHORIZATION", value: "Basic xyz")
    }
    
    func testRequestWithoutHeaders() throws {
        let url = URL(string: "https://example.com/api")!
        let request = URLRequest(url: url)
        let httpRequest = HTTPRequests.HTTPRequest(
            id: "test-1",
            timestamp: Date(),
            request: request,
            response: nil,
            responseData: nil,
            error: nil
        )
        
        // Test that assertions pass when no headers exist
        HTTPAssertHeaderNotExists(httpRequest, name: "any-header")
        HTTPAssertHeaderNotEqual(httpRequest, name: "any-header", value: "any-value")
    }
    
    func testCommonHTTPHeaders() throws {
        let url = URL(string: "https://api.github.com/repos")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer ghp_token", forHTTPHeaderField: "Authorization")
        request.setValue("MyApp/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        
        let httpRequest = HTTPRequests.HTTPRequest(
            id: "test-1",
            timestamp: Date(),
            request: request,
            response: nil,
            responseData: nil,
            error: nil
        )
        
        // Test common HTTP headers
        HTTPAssertHeader(httpRequest, name: "Content-Type", value: "application/json")
        HTTPAssertHeader(httpRequest, name: "Accept", value: "application/json")
        HTTPAssertHeader(httpRequest, name: "Authorization", value: "Bearer ghp_token")
        HTTPAssertHeader(httpRequest, name: "User-Agent", value: "MyApp/1.0 (iOS)")
        HTTPAssertHeader(httpRequest, name: "Accept-Encoding", value: "gzip, deflate, br")
        HTTPAssertHeader(httpRequest, name: "Accept-Language", value: "en-US,en;q=0.9")
        
        // Test existence
        HTTPAssertHeaderExists(httpRequest, name: "Content-Type")
        HTTPAssertHeaderExists(httpRequest, name: "Authorization")
        
        // Test non-existence
        HTTPAssertHeaderNotExists(httpRequest, name: "Cookie")
        HTTPAssertHeaderNotExists(httpRequest, name: "X-API-Key")
        
        // Test not equal
        HTTPAssertHeaderNotEqual(httpRequest, name: "Content-Type", value: "text/html")
        HTTPAssertHeaderNotEqual(httpRequest, name: "Authorization", value: "Bearer wrong-token")
    }
    
    func testHeadersWithSpecialCharacters() throws {
        let url = URL(string: "https://example.com/api")!
        var request = URLRequest(url: url)
        request.setValue("text/html; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("no-cache, no-store, must-revalidate", forHTTPHeaderField: "Cache-Control")
        request.setValue("attachment; filename=\"report.pdf\"", forHTTPHeaderField: "Content-Disposition")
        
        let httpRequest = HTTPRequests.HTTPRequest(
            id: "test-1",
            timestamp: Date(),
            request: request,
            response: nil,
            responseData: nil,
            error: nil
        )
        
        HTTPAssertHeader(httpRequest, name: "Content-Type", value: "text/html; charset=utf-8")
        HTTPAssertHeader(httpRequest, name: "Cache-Control", value: "no-cache, no-store, must-revalidate")
        HTTPAssertHeader(httpRequest, name: "Content-Disposition", value: "attachment; filename=\"report.pdf\"")
    }
}