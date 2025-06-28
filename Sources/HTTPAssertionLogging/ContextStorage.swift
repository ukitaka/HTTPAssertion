import Foundation

// MARK: - FileStorage Extension for Context
extension FileStorage {
    /// Shared storage for context data
    public static let context = FileStorage(subdirectory: "Context")
}

/// Generic context storage for sharing arbitrary Codable data between app and UI tests
public actor ContextStorage {
    public static let shared = ContextStorage()
    
    private init() {}
    
    /// Initializes the context storage directory
    public func initialize() async {
        await FileStorage.context.initialize()
    }
    
    /// Stores a context object with a given key
    public func store<T: Codable & Sendable>(_ context: T, forKey key: String) async throws {
        do {
            try await FileStorage.context.store(context, forKey: key)
        } catch {
            throw ContextStorageError.encodingFailed(error)
        }
    }
    
    /// Stores a dictionary context with a given key
    public func store(_ dictionary: [String: String], forKey key: String) async throws {
        do {
            try await FileStorage.context.store(dictionary, forKey: key)
        } catch {
            throw ContextStorageError.encodingFailed(error)
        }
    }
    
    /// Retrieves a context object for a given key
    public func retrieve<T: Codable & Sendable>(_ type: T.Type, forKey key: String) async throws -> T? {
        do {
            return try await FileStorage.context.retrieve(type, forKey: key)
        } catch {
            throw ContextStorageError.decodingFailed(error)
        }
    }
    
    /// Retrieves a dictionary context for a given key
    public func retrieve(forKey key: String) async throws -> [String: String]? {
        do {
            return try await FileStorage.context.retrieve([String: String].self, forKey: key)
        } catch {
            throw ContextStorageError.decodingFailed(error)
        }
    }
    
    /// Lists all stored context keys
    public func listKeys() async -> [String] {
        return await FileStorage.context.listKeys()
    }
    
    /// Removes a stored context for a given key
    public func remove(forKey key: String) async throws {
        try await FileStorage.context.remove(forKey: key)
    }
    
    /// Clears all stored contexts
    public func clear() async {
        await FileStorage.context.clear()
    }
}

/// Errors that can occur during context storage operations
public enum ContextStorageError: Error, LocalizedError {
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