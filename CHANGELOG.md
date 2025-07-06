# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2025-07-06

### Added
- Custom failure message support for all assertion methods using `@autoclosure () -> String` parameter
- HTTP response status code assertions with `HTTPAssertResponseStatus`
- `host` and `relativePath` parameters for more flexible URL matching
- XCTestCase extension methods: `performActionAndAssertRequested` and `performActionAndAssertResponse`
- Improved GitHub Actions workflows with reusable components

### Changed
- Assertion methods now support custom failure messages following XCTest patterns
- Convenience methods moved to XCTestCase extensions for better Swift API design
- Refactored `performActionAndAssertResponse` to use `waitForResponse` internally
- Simplified GitHub Actions workflow structure to eliminate code duplication

### Removed
- GitHub API calls from Demo app and UI tests to ensure reliable CI execution

### Documentation
- Added comprehensive CI/CD strategy documentation to CLAUDE.md
- Updated README.md with custom message examples for all assertion methods
- Enhanced API documentation with response status assertion examples

## [1.1.0] - 2025-06-30

### Added
- Optional type support in query parameter and header assertions
- Improved flexibility for assertion parameter types

### Changed
- Enhanced query parameter and header assertion methods to accept optional values

## [1.0.0] - 2025-06-30

### Changed
- Downgraded Swift tools version for broader compatibility
- Added comprehensive testing best practices documentation to README

### Documentation
- Added "Testing Best Practices" section explaining when to use HTTPAssertion vs unit tests
- Included testing pyramid guidance and recommended usage patterns

## [0.1.0] - 2025-06-29

### Added
- Initial release of HTTPAssertion
- HTTPAssertionLogging module for app-side HTTP request logging
- HTTPAssertionTesting module for XCUITest assertions
- HTTP request interception using method swizzling and custom URLProtocol
- Cross-process data sharing via simulator shared resources directory
- Flexible request matching by URL, HTTP method, headers, and query parameters
- Regular expression support for URL pattern matching
- Waiting functionality for asynchronous request verification
- Context API for sharing arbitrary data between app and tests
- Swift concurrency support with actors and async/await
- Thread-safe file-based storage system
- Example iOS app demonstrating usage
- Comprehensive test suite
- MIT License
- Documentation and contribution guidelines

### Features
- **HTTP Logging**: Automatic interception of all HTTP requests via URLSessionConfiguration swizzling
- **Assertion APIs**: `HTTPAssertRequested`, `HTTPAssertNotRequested`, `HTTPAssertRequestedOnce`
- **Advanced Matching**: Support for URL patterns, HTTP methods, headers, and query parameters
- **Async Support**: `waitForRequest` and `waitForResponse` functions with timeout support
- **Data Persistence**: JSON-based file storage in simulator shared directory
- **Swift 6.0 Compatibility**: Built with modern Swift concurrency features
- **Query Parameter Assertions**: `HTTPAssertQueryParameter`, `HTTPAssertQueryParameterExists`, etc.
- **Header Assertions**: `HTTPAssertHeader`, `HTTPAssertHeaderExists`, etc.
- **Convenience Methods**: `HTTPPerformActionAndAssertRequested` for combined UI actions and assertions
- **AllowedHosts Support**: Configure which hosts should be logged

[1.2.0]: https://github.com/ukitaka/HTTPAssertion/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/ukitaka/HTTPAssertion/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/ukitaka/HTTPAssertion/compare/0.1.0...1.0.0
[0.1.0]: https://github.com/ukitaka/HTTPAssertion/releases/tag/0.1.0