//
//  UIImageView+ASNetworking.swift
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
import ObjectiveC

public typealias ASImageUrlHandler = (_ image: UIImage?, _ isCache: Bool) -> Swift.Void
var ASImageViewAssociateKey: UInt8 = 0

extension URLSessionTask {
    var imageView: UIImageView? {
        get {
            return objc_getAssociatedObject(self, &ASImageViewAssociateKey) as? UIImageView
        }
        set(newValue) {
            objc_setAssociatedObject(self, &ASImageViewAssociateKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension UIImageView: ASNetworking {
    public func setImage(url: URL?, placeholder: UIImage? = nil, handler: ASImageUrlHandler? = nil) {
        self.image = placeholder
        
        guard let url = url else {
            return
        }
        
        cacheURLSession.getTasksWithCompletionHandler { (dataTasks: [URLSessionDataTask], uploadTasks: [URLSessionUploadTask], downloadTasks: [URLSessionDownloadTask]) in
            for dataTask in dataTasks {
                if dataTask.imageView == self {
                    dataTask.cancel()
                    break
                }
            }
        }
        
        let result = cacheRequest(URLRequest(url: url))
        if let cachedData = result.cachedData {
            let image = UIImage(data: cachedData)
            if let handler = handler {
                handler(image, true)
            } else {
                self.image = image
            }
        } else {
            result.response { result in
                switch result {
                case .success(let data):
                    let image = UIImage(data: data)
                    if let handler = handler {
                        handler(image, false)
                    } else {
                        self.image = image
                    }
                case .failure:
                    if let handler = handler {
                        handler(nil, false)
                    }
                }
            }.sessionTask?.imageView = self
        }
    }
    
    public func setImage(urlString: String, placeholder: UIImage? = nil, handler: ASImageUrlHandler? = nil) {
        setImage(url: URL(string: urlString), placeholder: placeholder, handler: handler)
    }
}
