import Foundation

/// Generic context storage for sharing arbitrary Codable data between app and UI tests
public enum Context {
    private static let storage = FileStorage(subdirectory: "Context")
    
    /// Initializes the context storage directory
    public static func initialize() async {
        await storage.initialize()
    }
    
    /// Stores a context object with a given key
    public static func store<T: Codable & Sendable>(_ context: T, forKey key: String) async throws {
        do {
            try await storage.store(context, forKey: key)
        } catch {
            throw ContextError.encodingFailed(error)
        }
    }
    
    /// Stores a dictionary context with a given key
    public static func store(_ dictionary: [String: String], forKey key: String) async throws {
        do {
            try await storage.store(dictionary, forKey: key)
        } catch {
            throw ContextError.encodingFailed(error)
        }
    }
    
    /// Retrieves a context object for a given key
    public static func retrieve<T: Codable & Sendable>(_ type: T.Type, forKey key: String) async throws -> T? {
        do {
            return try await storage.retrieve(type, forKey: key)
        } catch {
            throw ContextError.decodingFailed(error)
        }
    }
    
    /// Retrieves a dictionary context for a given key
    public static func retrieve(forKey key: String) async throws -> [String: String]? {
        do {
            return try await storage.retrieve([String: String].self, forKey: key)
        } catch {
            throw ContextError.decodingFailed(error)
        }
    }
    
    /// Lists all stored context keys
    public static func listKeys() async -> [String] {
        return await storage.listKeys()
    }
    
    /// Removes a stored context for a given key
    public static func remove(forKey key: String) async throws {
        try await storage.remove(forKey: key)
    }
    
    /// Clears all stored contexts
    public static func clear() async {
        await storage.clear()
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