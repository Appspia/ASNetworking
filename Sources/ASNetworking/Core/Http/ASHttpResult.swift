//
//  ASHttpResult.swift
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

