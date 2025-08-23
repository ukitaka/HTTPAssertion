import SwiftUI
import HTTPAssertionLogging

@main
struct DemoApp: App {
    init() {
        #if DEBUG
        HTTPAssertionLogging.start(
            allowedHosts: ["httpbin.org", "*.typicode.com", "*.google.com"],
            contextUpdateInterval: 2.0
        ) {
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
            
            try Context.store(userContext, forKey: "user_context")
            
            // Store additional context as typed object
            let appState = AppState(
                version: "1.0.0",
                build: "123",
                environment: "debug"
            )
            
            try Context.store(appState, forKey: "app_state")
        }
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
