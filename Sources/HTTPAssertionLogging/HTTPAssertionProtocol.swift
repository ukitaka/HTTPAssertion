import Foundation

/// Custom URLProtocol implementation to intercept all HTTP requests
@objc(HTTPAssertionProtocol)
final class HTTPAssertionProtocol: URLProtocol, @unchecked Sendable {
    
    private var sessionTask: URLSessionTask?
    private var responseData: Data?
    
    // MARK: - URLProtocol Methods
    
    override class func canInit(with request: URLRequest) -> Bool {
        // Check if we've already handled this request to avoid infinite loop
        if URLProtocol.property(forKey: "HTTPAssertionHandled", in: request) != nil {
            return false
        }
        
        // Only handle HTTP/HTTPS requests
        guard let url = request.url,
              let scheme = url.scheme,
              ["http", "https"].contains(scheme.lowercased()) else {
            return false
        }
        
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            return
        }
        
        // Mark this request as handled to avoid infinite loop
        URLProtocol.setProperty(true, forKey: "HTTPAssertionHandled", in: mutableRequest)
        
        let request = mutableRequest as URLRequest
        
        // Log the request
        HTTPRequestLogger.shared.logRequest(request)
        
        // Create a new session task
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        sessionTask = session.dataTask(with: request)
        sessionTask?.resume()
    }
    
    override func stopLoading() {
        sessionTask?.cancel()
        sessionTask = nil
        responseData = nil
    }
}

// MARK: - URLSessionDataDelegate
extension HTTPAssertionProtocol: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        responseData = Data()
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        responseData?.append(data)
        client?.urlProtocol(self, didLoad: data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
        
        // Log the response
        if let httpResponse = task.response as? HTTPURLResponse {
            HTTPRequestLogger.shared.logResponse(
                for: request,
                response: httpResponse,
                data: responseData,
                error: error
            )
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
        completionHandler(request)
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let protectionSpace = challenge.protectionSpace
        let sender = challenge.sender
        
        if protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                sender?.use(credential, for: challenge)
                completionHandler(.useCredential, credential)
                return
            }
        }
        
        completionHandler(.performDefaultHandling, nil)
    }
}