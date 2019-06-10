//
//  ASDownloadRequest.swift
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

public final class ASDownloadResult {
    typealias UpdatedHandler = (_ currentSize: Int64, _ totalSize: Int64) -> Swift.Void
    typealias CompletedHandler = (_ error: Error?) -> Swift.Void
    
    public var sessionTask: URLSessionTask?
    var updatedHandler: UpdatedHandler?
    var completedHandler: CompletedHandler?
    
    @discardableResult
    func updatedHandler(handler: UpdatedHandler?) -> ASDownloadResult {
        self.updatedHandler = handler
        return self
    }
    
    @discardableResult
    func completedHandler(handler: CompletedHandler?) -> ASDownloadResult {
        self.completedHandler = handler
        return self
    }
}

final class ASDownloadRequest {
    var result: ASDownloadResult
    var fileHandle: FileHandle?
    var tempFileSize: Int64 = 0
    var currentSize: Int64 = 0
    var totalSize: Int64 = 0
    
    init(session: URLSession, request: URLRequest, filePath: String) {
        self.result = ASDownloadResult()
        var request = request
        
        if FileManager.default.fileExists(atPath: filePath) {
            if let fileHandle = FileHandle(forWritingAtPath: filePath) {
                self.fileHandle = fileHandle
                self.tempFileSize = Int64(fileHandle.seekToEndOfFile())
                self.currentSize = self.tempFileSize
                
                request.setValue("bytes=\(tempFileSize)", forHTTPHeaderField: "Range")
            }
        } else {
            FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
            self.fileHandle = FileHandle(forWritingAtPath: filePath)
        }
        
        self.result.sessionTask = session.dataTask(with: request)
    }
}
