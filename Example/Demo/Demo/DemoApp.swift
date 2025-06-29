import SwiftUI
import HTTPAssertionLogging

@main
struct DemoApp: App {
    init() {
        #if DEBUG
        HTTPAssertionLogging.start()
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    #if DEBUG
                    print("DemoApp: Received URL: \(url)")
                    Task {
                        await handleURL(url)
                    }
                    #endif
                }
        }
    }
    
    #if DEBUG
    private func handleURL(_ url: URL) async {
        let handled = await Context.handleURL(url)
        print("DemoApp: URL handled: \(handled)")
        if handled {
            // Context update was requested, update the current context
            print("DemoApp: Updating current context...")
            await updateCurrentContext()
            print("DemoApp: Context update completed")
        }
    }
    
    /// Updates the current context with fresh data
    private func updateCurrentContext() async {
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
