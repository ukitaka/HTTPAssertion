import UIKit
import HTTPAssertionLogging

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        #if DEBUG
        HTTPAssertionLogging.start()
        Task {
            await Context.initialize()
        }
        #endif
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        #if DEBUG
        print("AppDelegate: Received URL: \(url)")
        Task {
            let handled = await Context.handleURL(url)
            print("AppDelegate: URL handled: \(handled)")
            if handled {
                // Context update was requested, update the current context
                print("AppDelegate: Updating current context...")
                await updateCurrentContext()
                print("AppDelegate: Context update completed")
            }
        }
        #endif
        return true
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
            
            // Store additional context as dictionary
            let appState = [
                "version": "1.0.0",
                "build": "123",
                "environment": "debug"
            ]
            
            try await Context.store(appState, forKey: "app_state")
            
        } catch {
            print("Failed to update context: \(error)")
        }
    }
}