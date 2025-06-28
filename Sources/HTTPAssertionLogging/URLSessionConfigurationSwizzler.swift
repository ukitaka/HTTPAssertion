import Foundation
import ObjectiveC

/// Handles method swizzling for URLSessionConfiguration to intercept requests
final class URLSessionConfigurationSwizzler {
    private static let lock = NSLock()
    private nonisolated(unsafe) static var isSwizzled = false
    
    static func swizzle() {
        lock.lock()
        defer { lock.unlock() }
        
        guard !isSwizzled else { return }
        isSwizzled = true
        
        swizzleDefaultConfiguration()
        swizzleEphemeralConfiguration()
    }
    
    static func unswizzle() {
        lock.lock()
        defer { lock.unlock() }
        
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