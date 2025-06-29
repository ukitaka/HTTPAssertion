import SwiftUI
import HTTPAssertionLogging

@main
struct DemoApp: App {
    init() {
        #if DEBUG
        HTTPAssertionLogging.start(contextUpdateInterval: 2.0) {
            do {
                // Update user context with current state
                let userContext = UserContext(
                    currentScreen: "ContentView",
                    lastUpdated: Date(),
                    username: "TestUser",
                    isLoggedIn: true,
                    preferences: [
                        "theme": "light",
                        "language": "en",
                        "notifications": "enabled"
                    ]
                )
                
                try await Context.store(userContext, forKey: "user_context")
                
                // Store additional context as typed object
                let appState = AppState(
                    version: "1.0.0",
                    build: "123",
                    environment: "debug"
                )
                
                try await Context.store(appState, forKey: "app_state")
                
            } catch {
                print("Failed to update context: \(error)")
            }
        }
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
