import Foundation

/// Main entry point for HTTPAssertion library
public final class HTTPAssertion {
    private static let lock = NSLock()
    private nonisolated(unsafe) static var _isStarted = false
    
    /// Starts HTTP request interception and logging
    public static func start() {
        lock.lock()
        defer { lock.unlock() }
        
        guard !_isStarted else { return }
        _isStarted = true
        
        // Perform method swizzling for URLSessionConfiguration
        URLSessionConfigurationSwizzler.swizzle()
        
        // Initialize storage
        HTTPRequestStorage.shared.initialize()
    }
    
    /// Stops HTTP request interception
    public static func stop() {
        lock.lock()
        defer { lock.unlock() }
        
        guard _isStarted else { return }
        _isStarted = false
        
        URLSessionConfigurationSwizzler.unswizzle()
    }
    
    /// Clears all recorded HTTP requests
    public static func clearRecordedRequests() {
        HTTPRequestStorage.shared.clear()
    }
}