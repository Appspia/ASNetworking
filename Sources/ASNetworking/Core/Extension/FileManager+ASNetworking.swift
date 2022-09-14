//
//  FileManager+ASNetworking.swift
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

// MARK: - Path
extension FileManager {
    public func ducumentFilePath(fileName: String?, folderName: String? = nil, isCreate: Bool = true) -> String {
        var path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
        if let folderName = folderName {
            path.append("/\(folderName)")
            if isCreate, !fileExists(atPath: path) {
                try? createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            }
        }
        if let fileName = fileName {
            path.append("/\(fileName)")
        }
        return path
    }
    
    public func cachesFilePath(fileName: String?, folderName: String, isCreate: Bool = true) -> String {
        var path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first ?? ""
        path.append("/\(folderName)")
        if isCreate, !fileExists(atPath: path) {
            try? createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        if let fileName = fileName {
            path.append("/\(fileName)")
        }
        return path
    }
    
    public func moveFile(atPath: String, toPath: String) {
        try? moveItem(atPath: atPath, toPath: toPath)
    }
    
    public func deleteFile(atPath: String) {
        try? removeItem(atPath: atPath)
    }
}

// MARK: - Disk Space
extension FileManager {
    public var totalDiskSpace: Int64 {
        do {
            let systemAttributes = try attributesOfFileSystem(forPath: NSHomeDirectory() as String)
            let space = (systemAttributes[.systemSize] as? NSNumber)?.int64Value
            return space ?? 0
        } catch {
            return 0
        }
    }
    
    public var freeDiskSpace: Int64 {
        do {
            let systemAttributes = try attributesOfFileSystem(forPath: NSHomeDirectory() as String)
            let freeSpace = (systemAttributes[.systemFreeSize] as? NSNumber)?.int64Value
            return freeSpace!
        } catch {
            return 0
        }
    }
    
    public var usedDiskSpace: Int64 {
        let usedSpace = totalDiskSpace - freeDiskSpace
        return usedSpace
    }
    
    public var totalDiskSpaceString: String {
        return ByteCountFormatter.string(fromByteCount: totalDiskSpace, countStyle: ByteCountFormatter.CountStyle.binary)
    }
    
    public var freeDiskSpaceString: String {
        return ByteCountFormatter.string(fromByteCount: freeDiskSpace, countStyle: ByteCountFormatter.CountStyle.binary)
    }
    
    public var usedDiskSpaceString: String {
        return ByteCountFormatter.string(fromByteCount: usedDiskSpace, countStyle: ByteCountFormatter.CountStyle.binary)
    }
}
