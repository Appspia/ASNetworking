//
//  ASNetworkManager.swift
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

import UIKit

final class ASNetworkManager: NSObject {
    static let shared = ASNetworkManager()
    var backgroundSessionCompletionHandler: (() -> Swift.Void)?
    var isErrorLoggig: Bool = false
    
    lazy var reachability: ASReachability = {
        let reachability = ASReachability(host: nil)
        if reachability.start() {
            print("Reachability start succeed")
        }
        return reachability
    }()
    
    lazy var httpURLSession: URLSession = {
        let httpSessionConfiguration = URLSessionConfiguration.default
        httpSessionConfiguration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: httpSessionConfiguration)
    }()
    
    lazy var cacheURLSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.urlCache = URLCache.shared
        return URLSession(configuration: configuration)
    }()
    
    lazy var downloadURLSession: URLSession = {
        var downloadSessionConfiguration: URLSessionConfiguration
        downloadSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "ASNetwork.DownloadBackgroundSession")
        return URLSession(configuration: downloadSessionConfiguration, delegate: self, delegateQueue: nil)
    }()
    
    lazy var uploadURLSession: URLSession = {
        let uploadSessionConfiguration: URLSessionConfiguration
        uploadSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "ASNetwork.UploadBackgroundSession")
        return URLSession(configuration: uploadSessionConfiguration, delegate: self, delegateQueue: nil)
    }()
    
    var downloadRequests: [URLSessionTask: ASDownloadRequest] = [:]
    var uploadRequests: [URLSessionTask: ASUploadRequest] = [:]
}

extension ASNetworkManager: URLSessionDelegate {
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        if let backgroundSessionCompletionHandler = self.backgroundSessionCompletionHandler {
            backgroundSessionCompletionHandler()
            self.backgroundSessionCompletionHandler = nil
        }
    }
}

extension ASNetworkManager: URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        if let uploadRequest = self.uploadRequests[task] {
            if let updatedHandler = uploadRequest.result.updatedHandler {
                DispatchQueue.main.async {
                    updatedHandler(totalBytesSent, totalBytesExpectedToSend)
                }
            }
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let downloadRequest = self.downloadRequests[task] {
            if let completedHandler = downloadRequest.result.completedHandler {
                DispatchQueue.main.async {
                    completedHandler(error)
                }
            }
            
            self.downloadRequests.removeValue(forKey: task)
        } else if let uploadRequest = self.uploadRequests[task] {
            if let completedHandler = uploadRequest.result.completedHandler {
                DispatchQueue.main.async {
                    completedHandler(error)
                }
            }
            
            self.uploadRequests.removeValue(forKey: task)
        }
    }
}

extension ASNetworkManager: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Swift.Void) {
        guard let downloadRequest = self.downloadRequests[dataTask], downloadRequest.fileHandle != nil, response.expectedContentLength != -1 else {
            completionHandler(.cancel)
            return
        }
        
        downloadRequest.totalSize = response.expectedContentLength + downloadRequest.tempFileSize
        
        if FileManager.default.freeDiskSpace < downloadRequest.totalSize {
            if let completedHandler = downloadRequest.result.completedHandler {
                DispatchQueue.main.async {
                    completedHandler(nil)
                }
            }
            return
        }
        
        completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let downloadRequest = self.downloadRequests[dataTask], let fileHandle = downloadRequest.fileHandle else {
            return
        }
        
        fileHandle.seekToEndOfFile()
        fileHandle.write(data)
        
        downloadRequest.currentSize += Int64(data.count)
        
        if let updatedHandler = downloadRequest.result.updatedHandler {
            DispatchQueue.main.async {
                updatedHandler(downloadRequest.currentSize, downloadRequest.totalSize)
            }
        }
    }
}
