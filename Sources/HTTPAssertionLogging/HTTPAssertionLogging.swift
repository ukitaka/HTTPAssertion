import Foundation
import ObjectiveC

/// Main entry point for HTTPAssertion library
public final class HTTPAssertionLogging {
    private static let lock = NSLock()
    private nonisolated(unsafe) static var isStarted = false
    private nonisolated(unsafe) static var isSwizzled = false
    private nonisolated(unsafe) static var contextUpdateTask: Task<Void, Never>?
    
    /// Starts HTTP request interception and logging
    public static func start() {
        startInternal(contextUpdateInterval: nil, contextUpdater: nil)
    }
    
    /// Starts HTTP request interception and logging with context updates
    public static func start(contextUpdateInterval: TimeInterval = 1.0, contextUpdater: @escaping @Sendable () async -> Void) {
        startInternal(contextUpdateInterval: contextUpdateInterval, contextUpdater: contextUpdater)
    }
    
    /// Internal implementation for starting HTTP assertion logging
    private static func startInternal(contextUpdateInterval: TimeInterval?, contextUpdater: (@Sendable () async -> Void)?) {
        lock.lock()
        defer { lock.unlock() }
        
        guard !isStarted else { return }
        isStarted = true
        
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
                    await updater()
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
