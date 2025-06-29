import Foundation

/// Example context data structure for demonstrating arbitrary data sharing
public struct UserContext: Codable, Sendable, Equatable {
    public let currentScreen: String
    public let lastUpdated: Date
    public let username: String
    public let isLoggedIn: Bool
    public let preferences: [String: String]
    
    public init(currentScreen: String, lastUpdated: Date, username: String, isLoggedIn: Bool, preferences: [String: String] = [:]) {
        self.currentScreen = currentScreen
        self.lastUpdated = lastUpdated
        self.username = username
        self.isLoggedIn = isLoggedIn
        self.preferences = preferences
    }
}

public struct AppState: Codable, Sendable {
    public let version: String
    public let build: String
    public let environment: String
    
    public init(version: String, build: String, environment: String) {
        self.version = version
        self.build = build
        self.environment = environment
    }
}
