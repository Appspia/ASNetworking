//
//  ASReachability.swift
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
import SystemConfiguration

public enum ASReachabilityStatus {
    case none
    case wwan
    case wifi
}

final class ASReachability {
    var reachability: SCNetworkReachability?
    var currentFlags = SCNetworkReachabilityFlags()
    var listener: ((ASReachabilityStatus) -> Void)?
    
    init(host: String?) {
        if let host = host {
            let reachability = SCNetworkReachabilityCreateWithName(nil, host)
            self.reachability = reachability
        } else {
            var address = sockaddr_in()
            address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
            address.sin_family = sa_family_t(AF_INET)
            
            let reachability = withUnsafePointer(to: &address, { pointer in
                return pointer.withMemoryRebound(to: sockaddr.self, capacity: MemoryLayout<sockaddr>.size) {
                    return SCNetworkReachabilityCreateWithAddress(nil, $0)
                }
            })
            self.reachability = reachability
        }
    }
}

extension ASReachability {
    func start() -> Bool {
        guard let reachability = self.reachability else { return false }
        
        // Call Back
        let callbackClosure: SCNetworkReachabilityCallBack? = { (reachability: SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutableRawPointer?) in
            guard let info = info else { return }
            let handler = Unmanaged<ASReachability>.fromOpaque(info).takeUnretainedValue()
            handler.flagsChanged(flags: flags)
        }
        
        // Context
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = Unmanaged<ASReachability>.passUnretained(self).toOpaque()
        
        // Set Callback
        guard SCNetworkReachabilitySetCallback(reachability, callbackClosure, &context) else { return false }
        
        // Set Dispatch Queue
        guard SCNetworkReachabilitySetDispatchQueue(reachability, DispatchQueue.main) else { return false }
        
        // Get first current flags
        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(reachability, &flags)
        flagsChanged(flags: flags)
        
        return true
    }
    
    func stop() {
        guard let reachability = self.reachability else { return }
        SCNetworkReachabilitySetCallback(reachability, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachability, nil)
    }
    
    func flagsChanged(flags: SCNetworkReachabilityFlags) {
        guard self.currentFlags != flags else { return }
        self.currentFlags = flags
        let status = reachabilityStatus()
        self.listener?(status)
    }
}

extension ASReachability {
    func reachabilityStatus() -> ASReachabilityStatus {
        guard isNetworkReachable(flags: self.currentFlags) else { return .none }
        
        if self.currentFlags.contains(.isWWAN) {
            return .wwan
        } else {
            return .wifi
        }
    }
    
    func isNetworkReachable(flags: SCNetworkReachabilityFlags) -> Bool {
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
        let canConnectWithoutUserInteraction = canConnectAutomatically && !flags.contains(.interventionRequired)
        return isReachable && (!needsConnection || canConnectWithoutUserInteraction)
    }
}
