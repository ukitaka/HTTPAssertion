import XCTest
@testable import HTTPAssertionLogging

final class HTTPAssertionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        HTTPAssertionLogging.stop()
        super.tearDown()
    }
    
    func testStartAndStop() {
        // Test that start and stop can be called without issues
        HTTPAssertionLogging.start()
        HTTPAssertionLogging.stop()
        
        // Can be called multiple times safely
        HTTPAssertionLogging.start()
        HTTPAssertionLogging.start()
        HTTPAssertionLogging.stop()
        HTTPAssertionLogging.stop()
    }
    
    
    func testRecordedHTTPRequestCodable() throws {
        // Test that RecordedHTTPRequest can be encoded and decoded
        let url = URL(string: "https://example.com")!
        let request = URLRequest(url: url)
        
        let recordedRequest = HTTPRequests.HTTPRequest(
            id: UUID().uuidString,
            timestamp: Date(),
            request: request,
            response: HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ),
            responseData: Data("test".utf8),
            error: nil
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let encoded = try encoder.encode(recordedRequest)
        let decoded = try decoder.decode(HTTPRequests.HTTPRequest.self, from: encoded)
        
        XCTAssertEqual(decoded.id, recordedRequest.id)
        XCTAssertEqual(decoded.request.url, recordedRequest.request.url)
        XCTAssertEqual(decoded.response?.statusCode, recordedRequest.response?.statusCode)
    }
}