import SwiftUI
import HTTPAssertionLogging

struct ContentView: View {
    @State private var searchQuery = ""
    @State private var isLoading = false
    @State private var lastRequestInfo = ""
    @State private var contextStored = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("HTTP Request Demo")
                .font(.largeTitle)
                .padding()
            
            // Context Storage Section
            HStack {
                Button("Store User Context") {
                    storeUserContext()
                }
                .buttonStyle(.borderedProminent)
                
                if contextStored {
                    Text("✓ Context stored")
                        .foregroundColor(.green)
                }
            }
            
            TextField("Enter search query", text: $searchQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button(action: performGoogleSearch) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                } else {
                    Text("Search on Google")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(searchQuery.isEmpty || isLoading)
            
            Button(action: performGitHubAPICall) {
                Text("Call GitHub API")
            }
            .buttonStyle(.bordered)
            
            Button(action: performHttpBinAPICall) {
                Text("Call HTTPBin API")
            }
            .buttonStyle(.bordered)
            
            Button(action: performJSONPlaceholderAPICall) {
                Text("Call JSONPlaceholder API")
            }
            .buttonStyle(.bordered)
            
            if !lastRequestInfo.isEmpty {
                Text("Last request: \(lastRequestInfo)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            // Store initial context when view appears
            storeUserContext()
        }
    }
    
    private func performGoogleSearch() {
        guard !searchQuery.isEmpty else { return }
        
        isLoading = true
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://www.google.com/search?q=\(encodedQuery)"
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { _, _, _ in
            DispatchQueue.main.async {
                self.isLoading = false
                self.lastRequestInfo = "Google search: \(searchQuery)"
            }
        }
        task.resume()
    }
    
    private func performGitHubAPICall() {
        guard let url = URL(string: "https://api.github.com/zen") else { return }
        
        let task = URLSession.shared.dataTask(with: url) { _, _, _ in
            DispatchQueue.main.async {
                self.lastRequestInfo = "GitHub API call"
            }
        }
        task.resume()
    }
    
    private func performHttpBinAPICall() {
        guard let url = URL(string: "https://httpbin.org/uuid") else { return }
        
        let task = URLSession.shared.dataTask(with: url) { _, _, _ in
            DispatchQueue.main.async {
                self.lastRequestInfo = "HTTPBin API call"
            }
        }
        task.resume()
    }
    
    private func performJSONPlaceholderAPICall() {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1") else { return }
        
        let task = URLSession.shared.dataTask(with: url) { _, _, _ in
            DispatchQueue.main.async {
                self.lastRequestInfo = "JSONPlaceholder API call"
            }
        }
        task.resume()
    }
    
    private func storeUserContext() {
        let deviceInfo = DeviceInfo(
            deviceModel: "iPhone Simulator",
            osVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        )
        
        let userContext = UserContext(
            userID: "test-user-123",
            username: "demouser",
            deviceInfo: deviceInfo
        )
        
        Task {
            do {
                try await HTTPAssertionLogging.storeContext(userContext, forKey: "currentUser")
                await MainActor.run {
                    contextStored = true
                }
            } catch {
                print("Failed to store context: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
}
