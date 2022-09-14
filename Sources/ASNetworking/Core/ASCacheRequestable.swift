//
//  ASCacheRequestable.swift
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

enum ASCacheResult {
    case success(Data)
    case failure(Data?, HTTPURLResponse?, Error?)
}

public final class ASCacheResponse {
    typealias ASCacheResultHandler = (ASCacheResult) -> Swift.Void
    
    var request: URLRequest?
    var sessionTask: URLSessionTask?
    var resultHandler: ASCacheResultHandler?
    var validStatusCodes: ClosedRange<Int> = 200...299
    var cachedData: Data?
    
    @discardableResult
    func response(handler: ASCacheResultHandler?) -> ASCacheResponse {
        resultHandler = handler
        return self
    }
    
    @discardableResult
    public func validate(statusCodes: ClosedRange<Int>) -> Self {
        validStatusCodes = statusCodes
        return self
    }
}

public protocol ASCacheRequestable {}

extension ASCacheRequestable {
    func cacheRequest(session: URLSession, request: URLRequest) -> ASCacheResponse {
        let cacheResponse = ASCacheResponse()
        cacheResponse.request = request
        
        let cachedRequest = URLRequest(url: request.url!, cachePolicy: .returnCacheDataDontLoad, timeoutInterval: request.timeoutInterval)
        if let cachedResponse = URLCache.shared.cachedResponse(for: cachedRequest) {
            cacheResponse.cachedData = cachedResponse.data
        } else {
            cacheResponse.sessionTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
                guard let resultHandler = cacheResponse.resultHandler else {
                    return
                }
                
                guard let httpURLResponse = response as? HTTPURLResponse, cacheResponse.validStatusCodes.contains(httpURLResponse.statusCode), error == nil else {
                    DispatchQueue.main.async {
                        resultHandler(.failure(data, response as? HTTPURLResponse, error))
                    }
                    return
                }
                
                guard let data = data else {
                    DispatchQueue.main.async {
                        resultHandler(.failure(nil, httpURLResponse, error))
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    resultHandler(.success(data))
                }
            }
        }
        return cacheResponse
    }
}
