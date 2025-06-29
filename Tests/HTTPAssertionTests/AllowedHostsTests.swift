import XCTest
@testable import HTTPAssertionLogging

final class AllowedHostsTests: XCTestCase {
    
    override func tearDown() {
        HTTPAssertionLogging.stop()
        super.tearDown()
    }
    
    func testAllowedHostsExactMatch() throws {
        // Test exact host matching
        HTTPAssertionLogging.start(allowedHosts: ["api.github.com", "httpbin.org"])
        
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("api.github.com"))
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("httpbin.org"))
        XCTAssertFalse(HTTPAssertionLogging.shouldRecordHost("www.github.com"))
        XCTAssertFalse(HTTPAssertionLogging.shouldRecordHost("github.com"))
        XCTAssertFalse(HTTPAssertionLogging.shouldRecordHost("google.com"))
        XCTAssertFalse(HTTPAssertionLogging.shouldRecordHost("subdomain.httpbin.org"))
    }
    
    func testAllowedHostsWildcardMatch() throws {
        // Test wildcard subdomain matching
        HTTPAssertionLogging.start(allowedHosts: ["*.github.com", "*.google.com"])
        
        // Should match any subdomain
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("api.github.com"))
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("www.github.com"))
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("subdomain.github.com"))
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("maps.google.com"))
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("www.google.com"))
        
        // Should match the domain itself (without subdomain)
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("github.com"))
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("google.com"))
        
        // Should not match different domains
        XCTAssertFalse(HTTPAssertionLogging.shouldRecordHost("httpbin.org"))
        XCTAssertFalse(HTTPAssertionLogging.shouldRecordHost("example.com"))
        XCTAssertFalse(HTTPAssertionLogging.shouldRecordHost("github.io"))
    }
    
    func testAllowedHostsMixedPatterns() throws {
        // Test combination of exact and wildcard patterns
        HTTPAssertionLogging.start(allowedHosts: ["api.github.com", "*.google.com", "httpbin.org"])
        
        // Exact matches
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("api.github.com"))
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("httpbin.org"))
        
        // Wildcard matches
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("maps.google.com"))
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("www.google.com"))
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("google.com"))
        
        // Should not match
        XCTAssertFalse(HTTPAssertionLogging.shouldRecordHost("www.github.com")) // Only api.github.com is allowed
        XCTAssertFalse(HTTPAssertionLogging.shouldRecordHost("github.com"))      // Only api.github.com is allowed
        XCTAssertFalse(HTTPAssertionLogging.shouldRecordHost("subdomain.httpbin.org")) // Only exact httpbin.org is allowed
        XCTAssertFalse(HTTPAssertionLogging.shouldRecordHost("example.com"))
    }
    
    func testAllowedHostsEmptyList() throws {
        // Test that empty list allows all hosts
        HTTPAssertionLogging.start(allowedHosts: [])
        
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("api.github.com"))
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("www.google.com"))
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("httpbin.org"))
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("example.com"))
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("any.domain.com"))
    }
    
    func testAllowedHostsNilHost() throws {
        // Test that nil host is always rejected
        HTTPAssertionLogging.start(allowedHosts: ["*.github.com"])
        
        XCTAssertFalse(HTTPAssertionLogging.shouldRecordHost(nil))
    }
    
    func testAllowedHostsSpecialCharacters() throws {
        // Test hosts with special regex characters are properly escaped
        HTTPAssertionLogging.start(allowedHosts: ["api-v1.example.com", "*.sub-domain.com"])
        
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("api-v1.example.com"))
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("test.sub-domain.com"))
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("sub-domain.com"))
        
        // Should not match similar but different domains
        XCTAssertFalse(HTTPAssertionLogging.shouldRecordHost("api_v1.example.com"))  // underscore vs dash
        XCTAssertFalse(HTTPAssertionLogging.shouldRecordHost("apitv1.example.com"))   // missing dash
    }
    
    func testAllowedHostsEdgeCases() throws {
        // Test edge cases with empty strings and dots
        HTTPAssertionLogging.start(allowedHosts: ["example.com"])
        
        // Empty strings and malformed hosts should not match
        XCTAssertFalse(HTTPAssertionLogging.shouldRecordHost(""))
        XCTAssertFalse(HTTPAssertionLogging.shouldRecordHost("."))
        XCTAssertFalse(HTTPAssertionLogging.shouldRecordHost(".."))
        
        // Valid host should match
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("example.com"))
    }
    
    func testAllowedHostsMultipleWildcards() throws {
        // Test multiple wildcard patterns
        HTTPAssertionLogging.start(allowedHosts: ["*.github.com", "*.gitlab.com", "*.bitbucket.org"])
        
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("api.github.com"))
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("www.gitlab.com"))
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("app.bitbucket.org"))
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("github.com"))
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("gitlab.com"))
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("bitbucket.org"))
        
        XCTAssertFalse(HTTPAssertionLogging.shouldRecordHost("github.io"))
        XCTAssertFalse(HTTPAssertionLogging.shouldRecordHost("gitlab.io"))
        XCTAssertFalse(HTTPAssertionLogging.shouldRecordHost("bitbucket.com"))
    }
    
    func testAllowedHostsInvalidPatterns() throws {
        // Test invalid wildcard patterns (missing dot after asterisk)
        HTTPAssertionLogging.start(allowedHosts: ["*github.com", "api.example.com"])
        
        // Invalid pattern "*github.com" should be ignored, only "api.example.com" should work
        XCTAssertFalse(HTTPAssertionLogging.shouldRecordHost("github.com"))
        XCTAssertFalse(HTTPAssertionLogging.shouldRecordHost("www.github.com"))
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("api.example.com"))
        XCTAssertFalse(HTTPAssertionLogging.shouldRecordHost("www.example.com"))
    }
    
    func testAllowedHostsEmptyWildcardPattern() throws {
        // Test pattern with just "*." which should be invalid
        HTTPAssertionLogging.start(allowedHosts: ["*.", "valid.com"])
        
        // "*." pattern should be ignored, only "valid.com" should work
        XCTAssertFalse(HTTPAssertionLogging.shouldRecordHost("anything.com"))
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("valid.com"))
        XCTAssertFalse(HTTPAssertionLogging.shouldRecordHost("www.valid.com"))
    }
    
    func testAllowedHostsAllInvalidPatterns() throws {
        // Test case where all patterns are invalid
        HTTPAssertionLogging.start(allowedHosts: ["*github.com", "*.", "*invalid"])
        
        // All patterns are invalid, so no hosts should match (fallback to allow all when no valid patterns)
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("github.com"))
        XCTAssertTrue(HTTPAssertionLogging.shouldRecordHost("any.domain.com"))
    }
}