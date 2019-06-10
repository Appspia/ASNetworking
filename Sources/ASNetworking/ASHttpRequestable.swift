//
//  ASHttpRequestable.swift
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

public enum ASHttpResult<T: Codable> {
    case success(T)
    case failure(Data?, HTTPURLResponse?, Error?)
}

extension ASHttpResult: CustomStringConvertible {
    public var description: String {
        var description = "---------------- HTTP RESULT ----------------\n"
        
        switch self {
        case .success(let item):
            description += "RESULT: succeed\n"
            if let data = item as? Data {
                description += String(data: data, encoding: .utf8) ?? ""
            } else if let string = item as? String {
                description += string
            } else {
                let encoder = JSONEncoder()
                if let data = try? encoder.encode(item) {
                    description += String(data: data, encoding: .utf8) ?? ""
                }
            }
        case .failure(let data, let response, let error):
            var statusString = "nil"
            if let response = response {
                statusString = String(response.statusCode)
            }
            
            var errorString = "nil"
            if let error = error {
                errorString = error.localizedDescription
            }
            
            var dataString = "nil"
            if let data = data {
                dataString = String(data: data, encoding: .utf8) ?? "nil"
            }
            
            description += """
            RESULT: failure
            STATUS: \(statusString)
            ERROR: \(errorString)
            DATA: \(dataString)
            """
        }
        
        description += "\n---------------------------------------------"
        return description
    }
}

public final class ASHttpResponse<T: Codable> {
    public typealias ASHttpResultHandler = (ASHttpResult<T>) -> Swift.Void
    
    public var sessionTask: URLSessionTask?
    var request: URLRequest?
    var resultHandler: ASHttpResultHandler?
    var validStatusCodes: ClosedRange<Int> = 200...299
    var logEnabled = false
    
    @discardableResult
    public func response(handler: ASHttpResultHandler?) -> Self {
        resultHandler = handler
        return self
    }
    
    @discardableResult
    public func validate(statusCodes: ClosedRange<Int>) -> Self {
        validStatusCodes = statusCodes
        return self
    }
    
    @discardableResult
    public func log() -> Self {
        logEnabled = true
        return self
    }
}

public protocol ASHttpRequestable {}

extension ASHttpRequestable {
    func httpRequest<T: Decodable>(session: URLSession, request: URLRequest) -> ASHttpResponse<T> {
        let httpResponse = ASHttpResponse<T>()
        httpResponse.request = request
        httpResponse.sessionTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            // Log
            if httpResponse.logEnabled {
                self.printLog(request: request, data: data, response: response, error: error)
            }
            
            guard let resultHandler = httpResponse.resultHandler else {
                return
            }
            
            guard let httpURLResponse = response as? HTTPURLResponse, (httpResponse.validStatusCodes.contains(httpURLResponse.statusCode)), error == nil else {
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
            
            var error = error
            var anyData: Any?
            
            if T.self == Data.self {
                anyData = data
            } else if T.self == String.self {
                anyData = String(data: data, encoding: .utf8)
            } else {
                let decoder = JSONDecoder()
                
                do {
                    let object: T = try decoder.decode(T.self, from: data)
                    anyData = object
                } catch let decodingError {
                    error = decodingError
                }
            }
            
            if anyData != nil, let anyData = anyData as? T {
                DispatchQueue.main.async {
                    resultHandler(.success(anyData))
                }
            } else {
                DispatchQueue.main.async {
                    resultHandler(.failure(data, httpURLResponse, error))
                }
            }
        }
        return httpResponse
    }
    
    func printLog(request: URLRequest, data: Data?, response: URLResponse?, error: Error?) {
        let urlString = request.url?.absoluteString ?? "nil"
        let headerString = request.allHTTPHeaderFields?.description ?? "nil"
        
        var bodyString = "nil"
        if let httpBody = request.httpBody {
            bodyString = String(data: httpBody, encoding: .utf8) ?? "nil"
        }
        
        var statusString = "nil"
        if let httpURLResponse = response as? HTTPURLResponse {
            statusString = String(httpURLResponse.statusCode)
        }
        
        var errorString = "nil"
        if let error = error {
            errorString = error.localizedDescription
        }
        
        var dataString = "nil"
        if let data = data {
            dataString = String(data: data, encoding: .utf8) ?? "nil"
        }
        
        print("""
            --------------- HTTP REQUEST ----------------
            URL: \(urlString)
            HEADER: \(headerString)
            BODY: \(bodyString)
            --------------- HTTP RESPONSE ---------------
            STATUS: \(statusString)
            ERROR: \(errorString)
            DATA: \(dataString)
            ---------------------------------------------
            """)
    }
}
