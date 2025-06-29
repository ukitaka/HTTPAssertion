import Foundation

/// Generic file-based storage for Codable data
actor FileStorage {
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let subdirectory: String
    
    internal var storageDirectory: URL? {
        #if targetEnvironment(simulator)
        // Use SIMULATOR_SHARED_RESOURCES_DIRECTORY for simulator
        if let sharedDir = ProcessInfo.processInfo.environment["SIMULATOR_SHARED_RESOURCES_DIRECTORY"] {
            let url = URL(fileURLWithPath: sharedDir)
                .appendingPathComponent("Library")
                .appendingPathComponent("Caches")
                .appendingPathComponent("HTTPAssertion")
                .appendingPathComponent(subdirectory)
            return url
        }
        #endif
        
        // Fallback to app's caches directory
        return fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("HTTPAssertion")
            .appendingPathComponent(subdirectory)
    }
    
    init(subdirectory: String) {
        self.subdirectory = subdirectory
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    /// Initializes the storage directory
    func initialize() {
        guard let directory = storageDirectory else { return }
        
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            print("HTTPAssertion: Failed to create storage directory (\(subdirectory)): \(error)")
        }
    }
    
    /// Stores a Codable object with a given key
    func store<T: Codable>(_ object: T, forKey key: String) throws {
        guard let directory = storageDirectory else {
            throw FileStorageError.noStorageDirectory
        }
        
        let fileURL = directory.appendingPathComponent("\(key).json")
        
        do {
            let data = try encoder.encode(object)
            // Use atomic write to update file in-place
            // This preserves creation date and updates modification date
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw FileStorageError.encodingFailed(error)
        }
    }
    
    /// Retrieves a Codable object for a given key
    func retrieve<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let directory = storageDirectory else {
            throw FileStorageError.noStorageDirectory
        }
        
        let fileURL = directory.appendingPathComponent("\(key).json")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode(type, from: data)
        } catch {
            throw FileStorageError.decodingFailed(error)
        }
    }
    
    /// Lists all stored keys
    func listKeys() -> [String] {
        guard let directory = storageDirectory else { return [] }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            return files.compactMap { file in
                guard file.pathExtension == "json" else { return nil }
                return file.deletingPathExtension().lastPathComponent
            }
        } catch {
            return []
        }
    }
    
    /// Removes a stored object for a given key
    func remove(forKey key: String) throws {
        guard let directory = storageDirectory else {
            throw FileStorageError.noStorageDirectory
        }
        
        let fileURL = directory.appendingPathComponent("\(key).json")
        
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }
    
    /// Clears all stored objects
    func clear() {
        guard let directory = storageDirectory else { return }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            for file in files where file.pathExtension == "json" {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("HTTPAssertion: Failed to clear storage (\(subdirectory)): \(error)")
        }
    }
    
    /// Loads all objects from disk
    func loadAll<T: Codable>(_ type: T.Type) -> [T] {
        guard let directory = storageDirectory else { return [] }
        
        var objects: [T] = []
        
        do {
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            
            for file in files where file.pathExtension == "json" {
                do {
                    let data = try Data(contentsOf: file)
                    let object = try decoder.decode(type, from: data)
                    objects.append(object)
                } catch {
                    // Skip corrupted files
                    continue
                }
            }
        } catch {
            return []
        }
        
        return objects
    }
    
    enum SortKey {
        case creationDate
        case modificationDate
    }
    
    func loadSorted<T: Codable>(_ type: T.Type, limit: Int? = nil, sortBy: SortKey = .modificationDate, ascending: Bool = true) -> [T] {
        guard let directory = storageDirectory else { return [] }
        
        do {
            let properties: [URLResourceKey] = [.contentModificationDateKey, .creationDateKey, .nameKey]
            let files = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: properties,
                options: .skipsHiddenFiles
            )
            
            let jsonFiles = files.filter { $0.pathExtension == "json" }
            
            let sortedFiles = jsonFiles.sorted(by: { file1, file2 in
                let date1: Date?
                let date2: Date?
                
                if sortBy == .creationDate {
                    date1 = try? file1.resourceValues(forKeys: [.creationDateKey]).creationDate
                    date2 = try? file2.resourceValues(forKeys: [.creationDateKey]).creationDate
                } else {
                    date1 = try? file1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                    date2 = try? file2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                }
                
                guard let d1 = date1, let d2 = date2 else {
                    return ascending
                }
                return ascending ? d1 < d2 : d1 > d2
            })
            
            let filesToLoad = limit.map { Array(sortedFiles.prefix($0)) } ?? sortedFiles
            
            var objects: [T] = []
            for file in filesToLoad {
                do {
                    let data = try Data(contentsOf: file)
                    let object = try decoder.decode(type, from: data)
                    objects.append(object)
                } catch {
                    // Skip corrupted files
                    continue
                }
            }
            
            return objects
        } catch {
            return []
        }
    }
}

/// Errors that can occur during file storage operations
enum FileStorageError: Error, LocalizedError {
    case noStorageDirectory
    case encodingFailed(Error)
    case decodingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .noStorageDirectory:
            return "No storage directory available"
        case .encodingFailed(let error):
            return "Failed to encode data: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        }
    }
}
