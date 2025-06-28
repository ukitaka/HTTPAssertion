import Foundation

/// Custom URLProtocol implementation to intercept all HTTP requests
@objc(HTTPAssertionProtocol)
final class HTTPAssertionProtocol: URLProtocol, @unchecked Sendable {
    
    static let httpAssertionInternalKey = "com.httpassertion.internal"
    
    private var response: URLResponse?
    private var responseData: NSMutableData?
    private lazy var session: URLSession = { [unowned self] in
        return URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }()
    
    // MARK: - URLProtocol Methods
    
    override class func canInit(with request: URLRequest) -> Bool {
        return canServeRequest(request)
    }
    
    override class func canInit(with task: URLSessionTask) -> Bool {
        guard let request = task.currentRequest else { return false }
        return canServeRequest(request)
    }
    
    private class func canServeRequest(_ request: URLRequest) -> Bool {
        // Check if we've already handled this request to avoid infinite loop
        guard URLProtocol.property(forKey: HTTPAssertionProtocol.httpAssertionInternalKey, in: request) == nil else {
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
        // Generate UUID for this request
        let requestID = UUID()
        let mutableRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        URLProtocol.setProperty(requestID.uuidString, forKey: HTTPAssertionProtocol.httpAssertionInternalKey, in: mutableRequest)

        // Log the request
        Task {
            let recordedRequest = RecordedHTTPRequest(
                id: requestID.uuidString,
                timestamp: Date(),
                request: request,
                response: nil,
                responseData: nil,
                error: nil
            )
            
            await HTTPRequestStorage.shared.store(recordedRequest)
        }
        
        session.dataTask(with: mutableRequest as URLRequest).resume()
    }
    
    override func stopLoading() {
        session.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
            self.session.invalidateAndCancel()
        }
    }
}

// MARK: - URLSessionDataDelegate
extension HTTPAssertionProtocol: URLSessionDataDelegate {
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        responseData?.append(data)
        client?.urlProtocol(self, didLoad: data)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.response = response
        responseData = NSMutableData()
        
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        defer {
            if let error = error {
                client?.urlProtocol(self, didFailWithError: error)
            } else {
                client?.urlProtocolDidFinishLoading(self)
            }
        }
        
        // Log the response
        if let response = response as? HTTPURLResponse,
           let requestIDString = URLProtocol.property(forKey: HTTPAssertionProtocol.httpAssertionInternalKey, in: request) as? String,
           let requestID = UUID(uuidString: requestIDString) {
            let data = (responseData ?? NSMutableData()) as Data
            Task {
                // Update the matching request with response using UUID
                await HTTPRequestStorage.shared.updateResponse(
                    requestID: requestID.uuidString,
                    response: response,
                    data: data,
                    error: error
                )
            }
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        let updatedRequest: URLRequest
        if URLProtocol.property(forKey: HTTPAssertionProtocol.httpAssertionInternalKey, in: request) != nil {
            let mutableRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
            URLProtocol.removeProperty(forKey: HTTPAssertionProtocol.httpAssertionInternalKey, in: mutableRequest)
            updatedRequest = mutableRequest as URLRequest
        } else {
            updatedRequest = request
        }
        
        client?.urlProtocol(self, wasRedirectedTo: updatedRequest, redirectResponse: response)
        completionHandler(updatedRequest)
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
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
