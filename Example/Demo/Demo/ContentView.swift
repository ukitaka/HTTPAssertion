import SwiftUI
import UIKit
import HTTPAssertionLogging

struct ContentView: View {
    @State private var searchQuery = ""
    @State private var isLoading = false
    @State private var lastRequestInfo = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("HTTP Request Demo")
                .font(.largeTitle)
                .padding()
            
            
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
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("HTTPAssertion-Demo/1.0", forHTTPHeaderField: "User-Agent")
        
        let task = URLSession.shared.dataTask(with: request) { _, _, _ in
            DispatchQueue.main.async {
                self.lastRequestInfo = "GitHub API call"
            }
        }
        task.resume()
    }
    
    private func performHttpBinAPICall() {
        guard let url = URL(string: "https://httpbin.org/get?source=demo&version=1.0&test_param=hello%20world") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("HTTPAssertion-Demo/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("demo-session-123", forHTTPHeaderField: "X-Session-ID")
        
        let task = URLSession.shared.dataTask(with: request) { _, _, _ in
            DispatchQueue.main.async {
                self.lastRequestInfo = "HTTPBin API call"
            }
        }
        task.resume()
    }
    
    private func performJSONPlaceholderAPICall() {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts?userId=1&page=1") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("HTTPAssertion-Demo/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("en-US", forHTTPHeaderField: "Accept-Language")
        
        let task = URLSession.shared.dataTask(with: request) { _, _, _ in
            DispatchQueue.main.async {
                self.lastRequestInfo = "JSONPlaceholder API call"
            }
        }
        task.resume()
    }
    
}

#Preview {
    ContentView()
}
