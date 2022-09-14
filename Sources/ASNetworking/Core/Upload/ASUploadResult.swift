//
//  ASUploadResult.swift
//  
//
//  Created by APPSPIA on 2022/08/25.
//

import Foundation

public final class ASUploadResult {
    typealias UpdatedHandler = (_ currentSize: Int64, _ totalSize: Int64) -> Swift.Void
    typealias CompletedHandler = (_ error: Error?) -> Swift.Void
    
    public var sessionTask: URLSessionTask?
    var updatedHandler: UpdatedHandler?
    var completedHandler: CompletedHandler?
    
    @discardableResult
    func updatedHandler(handler: UpdatedHandler?) -> ASUploadResult {
        self.updatedHandler = handler
        return self
    }
    
    @discardableResult
    func completedHandler(handler: CompletedHandler?) -> ASUploadResult {
        self.completedHandler = handler
        return self
    }
}
