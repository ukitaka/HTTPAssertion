import Foundation
import ObjectiveC

/// Main entry point for HTTPAssertion library
public final class HTTPAssertionLogging {
    private static let lock = NSLock()
    private nonisolated(unsafe) static var isStarted = false
    private nonisolated(unsafe) static var isSwizzled = false
    private nonisolated(unsafe) static var contextUpdateTask: Task<Void, Never>?
    // TODO: Switch to Swift Regex when iOS 15 support is dropped
    private nonisolated(unsafe) static var allowedHostRegex: NSRegularExpression?
    
    /// Starts HTTP request interception and logging
    public static func start(allowedHosts: [String] = []) {
        startInternal(allowedHosts: allowedHosts, contextUpdateInterval: nil, contextUpdater: nil)
    }
    
    /// Starts HTTP request interception and logging with context updates
    public static func start(allowedHosts: [String] = [], contextUpdateInterval: TimeInterval = 1.0, contextUpdater: @escaping @Sendable () async throws -> Void) {
        startInternal(allowedHosts: allowedHosts, contextUpdateInterval: contextUpdateInterval, contextUpdater: contextUpdater)
    }
    
    /// Internal implementation for starting HTTP assertion logging
    private static func startInternal(allowedHosts: [String], contextUpdateInterval: TimeInterval?, contextUpdater: (@Sendable () async throws -> Void)?) {
        lock.lock()
        defer { lock.unlock() }
        
        guard !isStarted else { return }
        isStarted = true
        
        // Set allowed hosts filter by creating combined regex
        self.allowedHostRegex = createHostRegex(from: allowedHosts)
        
        // Register custom URLProtocol
        URLProtocol.registerClass(HTTPAssertionProtocol.self)
        
        // Perform method swizzling for URLSessionConfiguration
        swizzle()
        
        // Initialize storage
        Task {
            await HTTPRequests.initialize()
            await Context.initialize()
        }
        
        // Start periodic context updates if provided
        if let interval = contextUpdateInterval, let updater = contextUpdater {
            contextUpdateTask = Task.detached {
                while !Task.isCancelled {
                    do {
                        try await updater()
                    } catch {
                        print("Context updater error: \(error)")
                    }
                    try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                }
            }
        }
    }
    
    /// Stops HTTP request interception
    public static func stop() {
        lock.lock()
        defer { lock.unlock() }
        
        guard isStarted else { return }
        isStarted = false
        
        // Cancel context update task
        contextUpdateTask?.cancel()
        contextUpdateTask = nil
        
        // Unregister custom URLProtocol
        URLProtocol.unregisterClass(HTTPAssertionProtocol.self)
        
        unswizzle()
    }
    
    /// Checks if a host should be recorded based on the allowed hosts filter
    internal static func shouldRecordHost(_ host: String?) -> Bool {
        guard let host = host, !host.isEmpty else { return false }
        
        // If no host filter is specified, record all
        guard let regex = allowedHostRegex else {
            return true
        }
        
        // Check if host matches the combined regex pattern
        let range = NSRange(location: 0, length: host.utf16.count)
        return regex.firstMatch(in: host, options: [], range: range) != nil
    }
    
    /// Creates a combined regex pattern from host specifications
    private static func createHostRegex(from hosts: [String]) -> NSRegularExpression? {
        guard !hosts.isEmpty else { return nil }
        
        let patterns: [String] = hosts.compactMap { hostSpec in
            if hostSpec.hasPrefix("*.") {
                // Convert *.example.com to pattern that matches any subdomain AND the domain itself
                let domain = String(hostSpec.dropFirst(2)) // Remove the "*."
                guard !domain.isEmpty else { return nil } // Invalid pattern like "*."
                let escapedDomain = NSRegularExpression.escapedPattern(for: domain)
                // Pattern matches either "domain.com" or "anything.domain.com"
                return "(^" + escapedDomain + "$|.*\\." + escapedDomain + "$)"
            } else if hostSpec.hasPrefix("*") {
                // Invalid pattern like "*github.com" (missing dot after asterisk)
                print("HTTPAssertion: Invalid host pattern '\(hostSpec)'. Wildcard patterns must start with '*.' (e.g., '*.github.com')")
                return nil
            } else {
                // Exact host match
                return "^" + NSRegularExpression.escapedPattern(for: hostSpec) + "$"
            }
        }
        
        // If no valid patterns remain, return nil (allow all hosts)
        guard !patterns.isEmpty else {
            print("HTTPAssertion: No valid host patterns found, allowing all hosts")
            return nil
        }
        
        // Combine all patterns with OR (|)
        let combinedPattern = patterns.joined(separator: "|")
        
        do {
            return try NSRegularExpression(pattern: combinedPattern, options: [])
        } catch {
            print("HTTPAssertion: Failed to create host regex pattern: \(error)")
            return nil
        }
    }
    
    // MARK: - Method Swizzling
    
    private static func swizzle() {
        guard !isSwizzled else { return }
        isSwizzled = true
        
        swizzleDefaultConfiguration()
        swizzleEphemeralConfiguration()
    }
    
    private static func unswizzle() {
        guard isSwizzled else { return }
        isSwizzled = false
        
        // Re-swizzle to restore original implementations
        swizzleDefaultConfiguration()
        swizzleEphemeralConfiguration()
    }
    
    private static func swizzleDefaultConfiguration() {
        let originalSelector = NSSelectorFromString("defaultSessionConfiguration")
        let swizzledSelector = #selector(URLSessionConfiguration.swizzled_defaultSessionConfiguration)
        
        swizzleClassMethod(
            class: URLSessionConfiguration.self,
            originalSelector: originalSelector,
            swizzledSelector: swizzledSelector
        )
    }
    
    private static func swizzleEphemeralConfiguration() {
        let originalSelector = NSSelectorFromString("ephemeralSessionConfiguration")
        let swizzledSelector = #selector(URLSessionConfiguration.swizzled_ephemeralSessionConfiguration)
        
        swizzleClassMethod(
            class: URLSessionConfiguration.self,
            originalSelector: originalSelector,
            swizzledSelector: swizzledSelector
        )
    }
    
    private static func swizzleClassMethod(class cls: AnyClass, originalSelector: Selector, swizzledSelector: Selector) {
        guard let metaClass = object_getClass(cls) else { return }
        
        guard let originalMethod = class_getClassMethod(cls, originalSelector),
              let swizzledMethod = class_getClassMethod(cls, swizzledSelector) else {
            return
        }
        
        let didAddMethod = class_addMethod(
            metaClass,
            originalSelector,
            method_getImplementation(swizzledMethod),
            method_getTypeEncoding(swizzledMethod)
        )
        
        if didAddMethod {
            class_replaceMethod(
                metaClass,
                swizzledSelector,
                method_getImplementation(originalMethod),
                method_getTypeEncoding(originalMethod)
            )
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}

// MARK: - URLSessionConfiguration Extensions
extension URLSessionConfiguration {
    
    @objc class func swizzled_defaultSessionConfiguration() -> URLSessionConfiguration {
        let configuration = swizzled_defaultSessionConfiguration()
        configuration.protocolClasses = [HTTPAssertionProtocol.self] + (configuration.protocolClasses ?? [])
        return configuration
    }
    
    @objc class func swizzled_ephemeralSessionConfiguration() -> URLSessionConfiguration {
        let configuration = swizzled_ephemeralSessionConfiguration()
        configuration.protocolClasses = [HTTPAssertionProtocol.self] + (configuration.protocolClasses ?? [])
        return configuration
    }
}
