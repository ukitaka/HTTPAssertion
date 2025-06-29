# CI/CD Setup for HTTPAssertion

This document describes the Continuous Integration setup for the HTTPAssertion project.

## GitHub Actions Workflows

### 1. CI Workflow (`ci.yml`)
**Trigger**: Push to `main`/`develop`, Pull Requests to `main`
- Runs Swift Package tests
- Builds Demo app for iOS Simulator
- Fast feedback for development

### 2. Test Workflow (`test.yml`) 
**Trigger**: Push to `main`, Pull Requests to `main`
- Comprehensive testing including UI tests
- Multiple jobs for different test types:
  - `swift-package-tests`: Core library tests
  - `demo-ui-tests`: Full UI testing on simulator
  - `demo-build-only`: Build verification fallback
  - `health-check`: Package validation

### 3. Simulator Tests (`simulator-tests.yml`)
**Trigger**: Manual dispatch, Daily at 2 AM UTC
- Dedicated UI testing environment
- Detailed test result collection
- Artifact uploads for debugging

## Test Coverage

### Swift Package Tests
- Unit tests for all HTTPAssertion components
- Query parameter and header assertion tests
- Host filtering and URLProtocol functionality
- File storage and context management

### Demo UI Tests  
- End-to-end testing with real HTTP requests
- Header and query parameter assertion validation
- Multiple API interaction scenarios
- Network request interception verification

## Requirements

- **Xcode**: 16.4
- **iOS Simulator**: iPhone 16, iOS 18.2+
- **macOS Runner**: macOS 15 (Sequoia)
- **Swift**: Compatible with Swift 6.0

## Running Tests Locally

### Swift Package Tests
```bash
swift test --verbose
```

### Demo UI Tests
```bash
cd Example/Demo
xcodebuild test \
  -scheme Demo \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:DemoUITests
```

## Artifacts and Results

The CI workflows generate several artifacts:

### Test Results
- `TestResults.xcresult`: Xcode test result bundle
- `test_summary.json`: JSON summary of test results
- `test_output.log`: Complete test execution log

### Build Artifacts
- Build logs and derived data caches
- Package dependency information

## Troubleshooting

### Common Issues

1. **Simulator Boot Timeout**
   - The CI automatically retries simulator operations
   - Timeout set to 120 seconds for boot process

2. **Network Access in Tests**
   - UI tests make real HTTP requests to public APIs
   - May occasionally fail due to network issues
   - `continue-on-error: true` prevents blocking the pipeline

3. **Memory Issues**
   - Tests include memory management improvements
   - URLProtocol lifecycle properly managed
   - Task cancellation with timeouts

### Debug Steps

1. Check the uploaded `TestResults.xcresult` artifact
2. Review `test_output.log` for detailed execution info
3. Use manual workflow dispatch for `simulator-tests.yml` to reproduce issues

## Configuration

### Caching Strategy
- Swift dependencies cached by `Package.swift` hash
- Xcode derived data cached by project file hash
- Separate caches for different workflow types

### Timeout Settings
- Swift Package Tests: 10 minutes
- Demo Build: 15 minutes  
- UI Tests: 20-25 minutes
- Overall workflow: 45 minutes

### Test Execution
- UI tests run with `parallel-testing-enabled NO` for stability
- Simulator tests use dedicated iPhone 16 simulator
- Code signing disabled for CI environment