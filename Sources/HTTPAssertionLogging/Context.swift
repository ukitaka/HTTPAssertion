import Foundation

/// Generic context storage for sharing arbitrary Codable data between app and UI tests
public enum Context {
    /// The underlying file storage for contexts
    public static let storage = FileStorage(subdirectory: "Context")
    
    /// Initializes the context storage directory
    public static func initialize() {
        storage.initialize()
    }
    
    /// Stores a context object with a given key
    public static func store<T: Codable & Sendable>(_ context: T, forKey key: String) throws {
        do {
            try storage.store(context, forKey: key)
        } catch {
            throw ContextError.encodingFailed(error)
        }
    }
    
    /// Retrieves a context object for a given key
    public static func retrieve<T: Codable & Sendable>(_ type: T.Type, forKey key: String) throws -> T? {
        do {
            return try storage.retrieve(type, forKey: key)
        } catch {
            throw ContextError.decodingFailed(error)
        }
    }
    
    /// Lists all stored context keys
    public static func listKeys() -> [String] {
        return storage.listKeys()
    }
    
    /// Removes a stored context for a given key
    public static func remove(forKey key: String) throws {
        try storage.remove(forKey: key)
    }
    
    /// Clears all stored contexts
    public static func clear() {
        storage.clear()
    }
    
}

/// Errors that can occur during context storage operations
public enum ContextError: Error, LocalizedError {
    case noStorageDirectory
    case encodingFailed(Error)
    case decodingFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .noStorageDirectory:
            return "No storage directory available"
        case .encodingFailed(let error):
            return "Failed to encode context: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode context: \(error.localizedDescription)"
        }
    }
}