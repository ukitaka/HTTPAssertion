import Foundation
import ObjectiveC

/// Main entry point for HTTPAssertion library
public final class HTTPAssertionLogging {
    private static let lock = NSLock()
    private nonisolated(unsafe) static var isStarted = false
    private nonisolated(unsafe) static var isSwizzled = false
    
    /// Starts HTTP request interception and logging
    public static func start() {
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
            HTTPRequests.initialize()
            await Context.initialize()
        }
    }
    
    /// Stops HTTP request interception
    public static func stop() {
        lock.lock()
        defer { lock.unlock() }
        
        guard isStarted else { return }
        isStarted = false
        
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
