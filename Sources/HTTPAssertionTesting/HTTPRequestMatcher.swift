import Foundation
import HTTPAssertionLogging

/// Matches HTTP requests based on various criteria
struct HTTPRequestMatcher {
    let url: String?
    let urlPattern: String?
    let host: String?
    let relativePath: String?
    let method: String?
    let headers: [String: String]?
    let queryParameters: [String: String]?
    
    var description: String {
        var parts: [String] = []
        if let url = url { parts.append("url=\(url)") }
        if let urlPattern = urlPattern { parts.append("urlPattern=\(urlPattern)") }
        if let host = host { parts.append("host=\(host)") }
        if let relativePath = relativePath { parts.append("relativePath=\(relativePath)") }
        if let method = method { parts.append("method=\(method)") }
        if let headers = headers { parts.append("headers=\(headers)") }
        if let queryParameters = queryParameters { parts.append("queryParameters=\(queryParameters)") }
        return parts.joined(separator: ", ")
    }
    
    func matches(_ request: HTTPRequests.HTTPRequest) -> Bool {
        // Check URL
        if let url = url {
            guard request.request.url?.absoluteString == url else { return false }
        }
        
        // Check URL pattern
        if let urlPattern = urlPattern {
            guard let requestURL = request.request.url?.absoluteString,
                  requestURL.range(of: urlPattern, options: .regularExpression) != nil else {
                return false
            }
        }
        
        // Check host
        if let host = host {
            guard request.request.url?.host == host else { return false }
        }
        
        // Check relative path
        if let relativePath = relativePath {
            guard request.request.url?.path == relativePath else { return false }
        }
        
        // Check method
        if let method = method {
            guard request.request.httpMethod?.uppercased() == method.uppercased() else { return false }
        }
        
        // Check headers
        if let headers = headers {
            guard let requestHeaders = request.request.allHTTPHeaderFields else { return false }
            for (key, value) in headers {
                guard requestHeaders[key] == value else { return false }
            }
        }
        
        // Check query parameters
        if let queryParameters = queryParameters {
            guard let components = request.request.url.flatMap({ URLComponents(url: $0, resolvingAgainstBaseURL: false) }),
                  let queryItems = components.queryItems else {
                return false
            }
            
            for (key, value) in queryParameters {
                guard queryItems.contains(where: { $0.name == key && $0.value == value }) else {
                    return false
                }
            }
        }
        
        return true
    }
}