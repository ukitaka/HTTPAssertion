import XCTest
@testable import HTTPAssertionLogging
@testable import HTTPAssertionTesting

final class QueryParameterTests: XCTestCase {
    
    override func tearDown() {
        HTTPAssertionLogging.stop()
        super.tearDown()
    }
    
    func testHTTPAssertQueryParameter() throws {
        // Create a request with query parameters
        let url = URL(string: "https://example.com/search?q=Swift%20programming&category=tech&page=1")!
        let request = URLRequest(url: url)
        let httpRequest = HTTPRequests.HTTPRequest(
            id: "test-1",
            timestamp: Date(),
            request: request,
            response: nil,
            responseData: nil,
            error: nil
        )
        
        // Test successful assertions
        HTTPAssertQueryParameter(httpRequest, name: "q", value: "Swift programming")
        HTTPAssertQueryParameter(httpRequest, name: "category", value: "tech")
        HTTPAssertQueryParameter(httpRequest, name: "page", value: "1")
    }
    
    func testHTTPAssertQueryParameterNotFound() throws {
        let url = URL(string: "https://example.com/search?q=test")!
        let request = URLRequest(url: url)
        let httpRequest = HTTPRequests.HTTPRequest(
            id: "test-1",
            timestamp: Date(),
            request: request,
            response: nil,
            responseData: nil,
            error: nil
        )
        
        // Test that a parameter with wrong value doesn't match
        HTTPAssertQueryParameterNotEqual(httpRequest, name: "q", value: "wrong_value")
        
        // Test that a nonexistent parameter doesn't have any value (should pass)
        HTTPAssertQueryParameterNotEqual(httpRequest, name: "nonexistent", value: "any_value")
    }
    
    func testHTTPAssertQueryParameterExists() throws {
        let url = URL(string: "https://example.com/search?q=test&empty=&category=tech")!
        let request = URLRequest(url: url)
        let httpRequest = HTTPRequests.HTTPRequest(
            id: "test-1",
            timestamp: Date(),
            request: request,
            response: nil,
            responseData: nil,
            error: nil
        )
        
        HTTPAssertQueryParameterExists(httpRequest, name: "q")
        HTTPAssertQueryParameterExists(httpRequest, name: "empty")
        HTTPAssertQueryParameterExists(httpRequest, name: "category")
    }
    
    func testHTTPAssertQueryParameterNotExists() throws {
        let url = URL(string: "https://example.com/search?q=test")!
        let request = URLRequest(url: url)
        let httpRequest = HTTPRequests.HTTPRequest(
            id: "test-1",
            timestamp: Date(),
            request: request,
            response: nil,
            responseData: nil,
            error: nil
        )
        
        HTTPAssertQueryParameterNotExists(httpRequest, name: "nonexistent")
        HTTPAssertQueryParameterNotExists(httpRequest, name: "category")
    }
    
    func testHTTPAssertQueryParameters() throws {
        let url = URL(string: "https://example.com/api?name=John%20Doe&age=30&city=New%20York")!
        let request = URLRequest(url: url)
        let httpRequest = HTTPRequests.HTTPRequest(
            id: "test-1",
            timestamp: Date(),
            request: request,
            response: nil,
            responseData: nil,
            error: nil
        )
        
        let expectedParams = [
            "name": "John Doe",
            "age": "30",
            "city": "New York"
        ]
        
        HTTPAssertQueryParameters(httpRequest, expectedParams)
    }
    
    func testHTTPRequestQueryParameter() throws {
        let url = URL(string: "https://example.com/search?q=Swift%20programming&category=tech")!
        let request = URLRequest(url: url)
        let httpRequest = HTTPRequests.HTTPRequest(
            id: "test-1",
            timestamp: Date(),
            request: request,
            response: nil,
            responseData: nil,
            error: nil
        )
        
        // Test the methods directly on HTTPRequest
        XCTAssertEqual(httpRequest.queryParameter(name: "q"), "Swift programming")
        XCTAssertEqual(httpRequest.queryParameter(name: "category"), "tech")
        XCTAssertNil(httpRequest.queryParameter(name: "nonexistent"))
    }
    
    func testHTTPRequestAllQueryParameters() throws {
        let url = URL(string: "https://example.com/api?name=John%20Doe&age=30&hobby=Swift%20Programming")!
        let request = URLRequest(url: url)
        let httpRequest = HTTPRequests.HTTPRequest(
            id: "test-1",
            timestamp: Date(),
            request: request,
            response: nil,
            responseData: nil,
            error: nil
        )
        
        // Test the method directly on HTTPRequest
        let allParams = httpRequest.allQueryParameters()
        XCTAssertEqual(allParams["name"], "John Doe")
        XCTAssertEqual(allParams["age"], "30")
        XCTAssertEqual(allParams["hobby"], "Swift Programming")
        XCTAssertEqual(allParams.count, 3)
    }
    
    func testQueryParametersWithSpecialCharacters() throws {
        // Test with various special characters that need URL encoding
        let url = URL(string: "https://example.com/search?query=hello%20world&symbols=%21%40%23%24%25")!
        let request = URLRequest(url: url)
        let httpRequest = HTTPRequests.HTTPRequest(
            id: "test-1",
            timestamp: Date(),
            request: request,
            response: nil,
            responseData: nil,
            error: nil
        )
        
        HTTPAssertQueryParameter(httpRequest, name: "query", value: "hello world")
        HTTPAssertQueryParameter(httpRequest, name: "symbols", value: "!@#$%")
        
        XCTAssertEqual(httpRequest.queryParameter(name: "query"), "hello world")
        XCTAssertEqual(httpRequest.queryParameter(name: "symbols"), "!@#$%")
    }
    
    func testRequestWithoutQueryParameters() throws {
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
        
        XCTAssertNil(httpRequest.queryParameter(name: "any"))
        XCTAssertTrue(httpRequest.allQueryParameters().isEmpty)
        
        HTTPAssertQueryParameterNotExists(httpRequest, name: "any")
    }
    
    func testEmptyQueryParameterValue() throws {
        let url = URL(string: "https://example.com/search?q=&category=tech")!
        let request = URLRequest(url: url)
        let httpRequest = HTTPRequests.HTTPRequest(
            id: "test-1",
            timestamp: Date(),
            request: request,
            response: nil,
            responseData: nil,
            error: nil
        )
        
        HTTPAssertQueryParameter(httpRequest, name: "q", value: "")
        HTTPAssertQueryParameterExists(httpRequest, name: "q")
        
        XCTAssertEqual(httpRequest.queryParameter(name: "q"), "")
    }
    
    func testMultipleParametersWithSameName() throws {
        // URLComponents handles multiple parameters with same name by keeping the last one
        let url = URL(string: "https://example.com/search?tag=swift&tag=programming&tag=ios")!
        let request = URLRequest(url: url)
        let httpRequest = HTTPRequests.HTTPRequest(
            id: "test-1",
            timestamp: Date(),
            request: request,
            response: nil,
            responseData: nil,
            error: nil
        )
        
        // The assertion should pass if any of the "tag" parameters matches
        HTTPAssertQueryParameterExists(httpRequest, name: "tag")
        
        // Check what value we get (URLComponents behavior may vary)
        let tagValue = httpRequest.queryParameter(name: "tag")
        XCTAssertNotNil(tagValue)
        XCTAssertTrue(["swift", "programming", "ios"].contains(tagValue!))
    }
    
    func testHTTPRequestQueryParameterMethods() throws {
        // Test the new methods directly on HTTPRequest
        let url = URL(string: "https://example.com/search?q=Swift%20programming&tag=swift&tag=programming&category=tech&empty=")!
        let request = URLRequest(url: url)
        let httpRequest = HTTPRequests.HTTPRequest(
            id: "test-1",
            timestamp: Date(),
            request: request,
            response: nil,
            responseData: nil,
            error: nil
        )
        
        // Test queryParameter method
        XCTAssertEqual(httpRequest.queryParameter(name: "q"), "Swift programming")
        XCTAssertEqual(httpRequest.queryParameter(name: "category"), "tech")
        XCTAssertEqual(httpRequest.queryParameter(name: "empty"), "")
        XCTAssertNil(httpRequest.queryParameter(name: "nonexistent"))
        
        // Test hasQueryParameter method
        XCTAssertTrue(httpRequest.hasQueryParameter(name: "q"))
        XCTAssertTrue(httpRequest.hasQueryParameter(name: "tag"))
        XCTAssertTrue(httpRequest.hasQueryParameter(name: "empty"))
        XCTAssertFalse(httpRequest.hasQueryParameter(name: "nonexistent"))
        
        // Test queryParameterValues method (for multiple values)
        let tagValues = httpRequest.queryParameterValues(name: "tag")
        XCTAssertEqual(tagValues.count, 2)
        XCTAssertTrue(tagValues.contains("swift"))
        XCTAssertTrue(tagValues.contains("programming"))
        
        let singleValues = httpRequest.queryParameterValues(name: "q")
        XCTAssertEqual(singleValues, ["Swift programming"])
        
        let noValues = httpRequest.queryParameterValues(name: "nonexistent")
        XCTAssertEqual(noValues, [])
        
        // Test allQueryParameters method
        let allParams = httpRequest.allQueryParameters()
        XCTAssertEqual(allParams["q"], "Swift programming")
        XCTAssertEqual(allParams["category"], "tech")
        XCTAssertEqual(allParams["empty"], "")
        // For multiple values with same name, URLComponents keeps the last one
        XCTAssertTrue(["swift", "programming"].contains(allParams["tag"]!))
    }
    
    func testHTTPAssertQueryParameterNotEqual() throws {
        let url = URL(string: "https://example.com/search?q=Swift%20programming&category=tech&empty=")!
        let request = URLRequest(url: url)
        let httpRequest = HTTPRequests.HTTPRequest(
            id: "test-1",
            timestamp: Date(),
            request: request,
            response: nil,
            responseData: nil,
            error: nil
        )
        
        // Test that parameters don't have wrong values
        HTTPAssertQueryParameterNotEqual(httpRequest, name: "q", value: "wrong query")
        HTTPAssertQueryParameterNotEqual(httpRequest, name: "category", value: "science")
        HTTPAssertQueryParameterNotEqual(httpRequest, name: "empty", value: "not empty")
        
        // Test that nonexistent parameters don't have any value (should always pass)
        HTTPAssertQueryParameterNotEqual(httpRequest, name: "nonexistent", value: "any value")
        
        // Test with URL encoding
        HTTPAssertQueryParameterNotEqual(httpRequest, name: "q", value: "Java programming") // Different decoded value
    }
}