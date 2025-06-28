import Foundation
import HTTPAssertionLogging

/// Retrieves a stored context object for a given key
public func HTTPRetrieveContext<T: Codable & Sendable>(_ type: T.Type, forKey key: String) async throws -> T? {
    return try await ContextStorage.shared.retrieve(type, forKey: key)
}

/// Retrieves a stored dictionary context for a given key
public func HTTPRetrieveContext(forKey key: String) async throws -> [String: String]? {
    return try await ContextStorage.shared.retrieve(forKey: key)
}

/// Lists all stored context keys
public func HTTPListContextKeys() async -> [String] {
    return await ContextStorage.shared.listKeys()
}

/// Removes a stored context for a given key
public func HTTPRemoveContext(forKey key: String) async throws {
    try await ContextStorage.shared.remove(forKey: key)
}

/// Clears all stored contexts
public func HTTPClearAllContexts() async {
    await ContextStorage.shared.clear()
}