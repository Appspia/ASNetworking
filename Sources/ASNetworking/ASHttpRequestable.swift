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
        var description = "--------------- HTTP RESULT -----------------\n"
    
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
            
            var errorString = error?.localizedDescription ?? "nil"
            if let decodingError = error as? DecodingError {
                var decodingErrorContext: DecodingError.Context?
                
                switch decodingError {
                case .typeMismatch(_, let context):
                    decodingErrorContext = context
                case .valueNotFound(_, let context):
                    decodingErrorContext = context
                case .keyNotFound(_, let context):
                    decodingErrorContext = context
                case .dataCorrupted(let context):
                    decodingErrorContext = context
                @unknown default: break
                }
                
                if let context = decodingErrorContext {
                    errorString += " \(context.codingPath.debugDescription) \(context.debugDescription)"
                }
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
            guard let httpURLResponse = response as? HTTPURLResponse, (httpResponse.validStatusCodes.contains(httpURLResponse.statusCode)), error == nil else {
                DispatchQueue.main.async {
                    if httpResponse.logEnabled || ASNetworkManager.shared.isErrorLoggig {
                        self.logPrinting(request: request, data: data, response: response, error: error)
                    }
                    httpResponse.resultHandler?(.failure(data, response as? HTTPURLResponse, error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    if httpResponse.logEnabled || ASNetworkManager.shared.isErrorLoggig {
                        self.logPrinting(request: request, data: data, response: response, error: error)
                    }
                    httpResponse.resultHandler?(.failure(nil, httpURLResponse, error))
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
            
            DispatchQueue.main.async {
                if anyData != nil, let anyData = anyData as? T {
                    if httpResponse.logEnabled {
                        self.logPrinting(request: request, data: data, response: response, error: error)
                    }
                    httpResponse.resultHandler?(.success(anyData))
                } else {
                    if httpResponse.logEnabled || ASNetworkManager.shared.isErrorLoggig {
                        self.logPrinting(request: request, data: data, response: response, error: error)
                    }
                    httpResponse.resultHandler?(.failure(data, httpURLResponse, error))
                }
            }
        }
        return httpResponse
    }
    
    func logPrinting(request: URLRequest, data: Data?, response: URLResponse?, error: Error?) {
        let urlString = request.url?.absoluteString ?? "nil"
        let headerString = jsonDicToPrettyString(request.allHTTPHeaderFields) ?? "nil"
        let bodyString = dataToPrettyString(request.httpBody) ?? "nil"
        
        var statusString = "nil"
        var httpResponseHeader = "nil"
        if let httpURLResponse = response as? HTTPURLResponse {
            statusString = String(httpURLResponse.statusCode)
            httpResponseHeader = jsonDicToPrettyString(httpURLResponse.allHeaderFields) ?? "nil"
        }
      
        var errorString = error?.localizedDescription ?? "nil"
        if let decodingError = error as? DecodingError {
            var decodingErrorContext: DecodingError.Context?
            
            switch decodingError {
            case .typeMismatch(_, let context):
                decodingErrorContext = context
            case .valueNotFound(_, let context):
                decodingErrorContext = context
            case .keyNotFound(_, let context):
                decodingErrorContext = context
            case .dataCorrupted(let context):
                decodingErrorContext = context
            @unknown default: break
            }
            
            if let context = decodingErrorContext {
                errorString += " \(context.codingPath.debugDescription) \(context.debugDescription)"
            }
        }

        let dataString = dataToPrettyString(data) ?? "nil"

        print("""
        --------------- HTTP REQUEST ----------------
        URL: \(urlString)
        HEADER: \(headerString)
        BODY: \(bodyString)
        --------------- HTTP RESPONSE ---------------
        URL: \(urlString)
        HEADER: \(httpResponseHeader)
        STATUS: \(statusString)
        ERROR: \(errorString)
        DATA: \(dataString)
        ---------------------------------------------
        """)
    }
    
    func jsonDicToPrettyString(_ jsonDic: Any?) -> String? {
        guard let jsonDic = jsonDic else { return nil }
        guard let data = try? JSONSerialization.data(withJSONObject: jsonDic, options: .prettyPrinted) else { return nil }
        guard let dataString = String(data: data, encoding: .utf8) else { return nil }
        return dataString
    }
    
    func dataToPrettyString(_ data: Data?) -> String? {
        guard let data = data else { return nil }
        guard let jsonFoundationObj = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else { return String(data: data, encoding: .utf8) }
        guard let jsonDataFieldWithEmptyCharacters = try? JSONSerialization.data(withJSONObject: jsonFoundationObj, options: .prettyPrinted) else { return nil }
        guard let dataString = String(data: jsonDataFieldWithEmptyCharacters, encoding: .utf8) else { return nil }
        return dataString
    }
}
