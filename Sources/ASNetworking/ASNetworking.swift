//
//  ASNetworking.swift
//
//  Copyright (c) 2016-2018 Appspia Studio. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

public protocol ASNetworking: ASHttpRequestable, ASCacheRequestable {}

// MARK: - Common

extension ASNetworking {
    public func setBackgroundSessionCompletionHandler(backgroundSessionCompletionHandler: (() -> Swift.Void)?) {
        ASNetworkManager.shared.backgroundSessionCompletionHandler = backgroundSessionCompletionHandler
    }
    
    public func reachability() -> ASReachabilityStatus {
        return ASNetworkManager.shared.reachability.reachabilityStatus()
    }
    
    public func setReachabilityListener(listener: @escaping (ASReachabilityStatus) -> Void) {
        ASNetworkManager.shared.reachability.listener = listener
    }
    
    public func setErrorLogging(isLogging: Bool) {
        ASNetworkManager.shared.isErrorLoggig = isLogging
    }
}

// MARK: - Http

extension ASNetworking {
    public var httpURLSession: URLSession {
        return ASNetworkManager.shared.httpURLSession
    }
    
    public func httpRequest<T: Codable>(_ request: URLRequest) -> ASHttpResponse<T> {
        let response: ASHttpResponse<T> = httpRequest(session: httpURLSession, request: request)
        response.sessionTask?.resume()
        return response
    }
    
    public func httpRequest<T: Decodable>(requestData: ASRequestData) -> ASHttpResponse<T> {
        let request = URLRequest(requestData: requestData)
        return httpRequest(request)
    }
}

// MARK: - Cache

extension ASNetworking {
    public var cacheURLSession: URLSession {
        return ASNetworkManager.shared.cacheURLSession
    }
    
    public func cacheRequest(_ request: URLRequest) -> ASCacheResponse {
        let response = cacheRequest(session: cacheURLSession, request: request)
        response.sessionTask?.resume()
        return response
    }
    
    public func cacheRequest(requestData: ASRequestData) -> ASCacheResponse {
        let request = URLRequest(requestData: requestData)
        return cacheRequest(request)
    }
  
    public func setCacheCapacity(memory: Int, disk: Int) {
        URLCache.shared = URLCache(memoryCapacity: memory, diskCapacity: disk, diskPath: nil)
    }
}

// MARK: - Download

extension ASNetworking {
    public var downloadURLSession: URLSession {
        return ASNetworkManager.shared.downloadURLSession
    }
    
    public func downloadRequest(_ request: URLRequest, filePath: String) -> ASDownloadResult {
        let downloadRequest = ASDownloadRequest(session: downloadURLSession, request: request, filePath: filePath)
        if let sessionTask = downloadRequest.result.sessionTask {
            ASNetworkManager.shared.downloadRequests[sessionTask] = downloadRequest
            sessionTask.resume()
        }
        return downloadRequest.result
    }
    
    public func downloadRequest(requestData: ASRequestData, filePath: String) -> ASDownloadResult {
        let request = URLRequest(requestData: requestData)
        return downloadRequest(request, filePath: filePath)
    }
}

// MARK: - Upload

extension ASNetworking {
    public var uploadURLSession: URLSession {
        return ASNetworkManager.shared.uploadURLSession
    }
    
    public func uploadRequest(_ request: URLRequest, filePath: String) -> ASUploadResult {
        let uploadRequest = ASUploadRequest(session: uploadURLSession, request: request, filePath: filePath)
        if let sessionTask = uploadRequest.result.sessionTask {
            ASNetworkManager.shared.uploadRequests[sessionTask] = uploadRequest
            sessionTask.resume()
        }
        return uploadRequest.result
    }
    
    public func uploadRequest(requestData: ASRequestData, filePath: String) -> ASUploadResult {
        let request = URLRequest(requestData: requestData)
        return uploadRequest(request, filePath: filePath)
    }
}
