//
//  URLRequest+ASNetworking.swift
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

public enum ASHttpMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public enum ASPercentEncoding: String {
    case url
    case alphanumerics
    case rfc3986
    case w3cHtml5
    
    func percentEncoding(_ string: String) -> String {
        switch self {
        case .url:
            return string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? string
        case .alphanumerics:
            return string.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? string
        case .rfc3986:
            var characterSet = CharacterSet.alphanumerics
            characterSet.insert(charactersIn: "-._~/?")
            return string.addingPercentEncoding(withAllowedCharacters: characterSet) ?? string
        case .w3cHtml5:
            var characterSet = CharacterSet.alphanumerics
            characterSet.insert(charactersIn: "*-._ ")
            return string.addingPercentEncoding(withAllowedCharacters: characterSet)?.replacingOccurrences(of: " ", with: "+") ?? string
        }
    }
}

public enum ASFormDataType {
    case data
    case png
    case jpg
    case custom(String)
    
    var contentType: String {
        switch self {
        case .data:
            return "application/octet-stream"
        case .png:
            return "image/png"
        case .jpg:
            return "image/jpeg"
        case let .custom(value):
            return value
        }
    }
}

public struct ASFormDataItem {
    public var type: ASFormDataType
    public var name: String
    public var data: Data
    public var fileName: String
    
    public init(type: ASFormDataType, name: String, data: Data, fileName: String?) {
        self.type = type
        self.name = name
        self.data = data
        self.fileName = fileName ?? NSUUID().uuidString
    }
}

public class ASRequestData {
    public var urlString: String
    public var httpMethod: ASHttpMethod
    public var headerFields: [String: String] = [:]
    public var parameters: [String: Any] = [:]
    public var parameterEncoding: ASPercentEncoding = .alphanumerics
    public var bodyData: Data?
    
    public var cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalCacheData
    public var timeoutInterval: TimeInterval = 60
    
    // MultiPart
    public var formDataItems: [ASFormDataItem] = []
    
    public init(urlString: String, httpMethod: ASHttpMethod) {
        self.urlString = urlString
        self.httpMethod = httpMethod
    }
    
  func parameterComponents(fromKey key: String, value: Any) -> [(String, String)] {
      var components: [(String, String)] = []
    
    if let dictionary = value as? [String: Any] {
        for (nestedKey, value) in dictionary {
            components += parameterComponents(fromKey: "\(key)[\(nestedKey)]", value: value)
        }
    } else if let array = value as? [Any] {
        for value in array {
            components += parameterComponents(fromKey: "\(key)[]", value: value)
        }
    } else {
          components.append((key, self.parameterEncoding.percentEncoding("\(value)")))
    }
    
    return components
  }
}

extension URLRequest {
    public init(requestData: ASRequestData) {
        var urlString = ASPercentEncoding.url.percentEncoding(requestData.urlString)
        
        var isBodyParameter = false
        var paramString: String = ""
        let parameters = requestData.parameters
        
        if requestData.formDataItems.count > 0 {
            isBodyParameter = true
        } else {
            switch requestData.httpMethod {
            case .post, .put:
                isBodyParameter = true
            default:
                isBodyParameter = false
            }
            
            // Param String
            if parameters.count > 0 {
                var components: [(String, String)] = []
                for key in parameters.keys.sorted(by: <) {
                    if let value = parameters[key] {
                        components += requestData.parameterComponents(fromKey: key, value: value)
                    }
                }
                paramString.append(components.map { "\($0)=\($1)" }.joined(separator: "&"))
                
                if !isBodyParameter {
                    urlString.append("?\(paramString)")
                }
            }
        }
        
        guard let url = URL(string: urlString) else {
            fatalError("ASNetwork URL Error : \(urlString)")
        }
        
        self.init(url: url, cachePolicy: requestData.cachePolicy, timeoutInterval: requestData.timeoutInterval)
        self.httpMethod = requestData.httpMethod.rawValue
        self.allHTTPHeaderFields = requestData.headerFields
        
        // Http Body
        if let bodyData = requestData.bodyData {
            self.httpBody = bodyData
        } else if isBodyParameter {
            var httpBody = Data()
            
            if requestData.formDataItems.count > 0 {
                let boundary = "---BOUNDARY---"
                let contentType = "multipart/form-data; boundary=\(boundary)"
                self.setValue(contentType, forHTTPHeaderField: "Content-type")
                
                for item in requestData.formDataItems {
                    httpBody.append(string: "--\(boundary)\r\n")
                    httpBody.append(string: "Content-Disposition: form-data; name=\"\(item.name)\"; filename=\"\(item.fileName)\"\r\n")
                    httpBody.append(string: "Content-Type: \(item.type.contentType)\r\n\r\n")
                    httpBody.append(item.data)
                    httpBody.append(string: "\r\n")
                }
                
                httpBody.append(string: "--\(boundary)--\r\n")
            } else if !paramString.isEmpty {
                httpBody.append(string: paramString)
            }
            
            self.httpBody = httpBody
        }
    }
}

extension Data {
    mutating func append(string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}
