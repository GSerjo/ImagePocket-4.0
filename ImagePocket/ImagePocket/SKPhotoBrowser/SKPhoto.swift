//
//  SKPhoto.swift
//  SKViewExample
//
//  Created by suzuki_keishi on 2015/10/01.
//  Copyright © 2015 suzuki_keishi. All rights reserved.
//

import UIKit
import Photos

@objc public protocol SKPhotoProtocol: NSObjectProtocol {
    var underlyingImage: UIImage! { get }
    var caption: String! { get }
    var index: Int { get set}
    var contentMode: UIViewContentMode { get set }
    func loadUnderlyingImageAndNotify()
    func checkCache()
}

// MARK: - SKPhoto
open class SKPhoto: NSObject, SKPhotoProtocol {
    
    open var underlyingImage: UIImage!
    open var photoURL: String!
    open var contentMode: UIViewContentMode = .scaleAspectFill
    open var shouldCachePhotoURLImage: Bool = false
    open var caption: String!
    open var index: Int = 0
    public var _asset: PHAsset

    init(asset: PHAsset) {
        _asset = asset
        super.init()
    }
    
//    convenience init(image: UIImage) {
//        self.init()
//        underlyingImage = image
//    }
//
//    convenience init(url: String) {
//        self.init()
//        photoURL = url
//    }
//
//    convenience init(url: String, holder: UIImage?) {
//        self.init()
//        photoURL = url
//        underlyingImage = holder
//    }
    
//    convenience init(asset: PHAsset){
//        self.init()
//        _asset = asset
//    }
    
    open func checkCache() {
        guard let photoURL = photoURL else {
            return
        }
        guard shouldCachePhotoURLImage else {
            return
        }
        
        if SKCache.sharedCache.imageCache is SKRequestResponseCacheable {
            let request = URLRequest(url: URL(string: photoURL)!)
            if let img = SKCache.sharedCache.imageForRequest(request) {
                underlyingImage = img
            }
        } else {
            if let img = SKCache.sharedCache.imageForKey(photoURL) {
                underlyingImage = img
            }
        }
    }
    
//    private var targetSize: CGSize {
//        return CGSize(width: SKMesurement.screenWidth * SKMesurement.screenScale,
//                      height: SKMesurement.screenHeight * SKMesurement.screenScale)
//    }
    
    public func loadUnderlyingImageAndNotify() -> Void {
        
        ImageLoader.load(asset: _asset, onComplete: { image in
            if let image = image {
                DispatchQueue.main.async {
                    self.underlyingImage = image
                    self.loadUnderlyingImageComplete()
                }
            }
            else {
                self.loadUnderlyingImageComplete()
            }
        })
        
//        let options = PHImageRequestOptions()
//        options.deliveryMode = .highQualityFormat
//        options.isNetworkAccessAllowed = true
//        options.isSynchronous = false
//
//        PHImageManager.default().requestImage(for: _asset,
//                                              targetSize: CGSize(width: _asset.pixelWidth, height: _asset.pixelHeight),
//                                              contentMode: .aspectFit,
//                                              options: options,
//                                              resultHandler: { image, info in
//                                                                if let image = image {
//                                                                    DispatchQueue.main.async {
//                                                                        self.underlyingImage = image
//                                                                        self.loadUnderlyingImageComplete()
//                                                                    }
//                                                                }
//                                                                else {
//                                                                    print(info!)
//                                                                    self.loadUnderlyingImageComplete()
//                                                                }
//
//        })
    }
    
//    open func loadUnderlyingImageAndNotify() {
//        guard photoURL != nil, let URL = URL(string: photoURL) else { return }
//
//        // Fetch Image
//        let session = URLSession(configuration: URLSessionConfiguration.default)
//            var task: URLSessionTask?
//            task = session.dataTask(with: URL, completionHandler: { [weak self] (data, response, error) in
//                guard let `self` = self else { return }
//
//                defer { session.finishTasksAndInvalidate() }
//
//                guard error == nil else {
//                    DispatchQueue.main.async {
//                        self.loadUnderlyingImageComplete()
//                    }
//                    return
//                }
//
//                if let data = data, let response = response, let image = UIImage(data: data) {
//                    if self.shouldCachePhotoURLImage {
//                        if SKCache.sharedCache.imageCache is SKRequestResponseCacheable {
//                            SKCache.sharedCache.setImageData(data, response: response, request: task?.originalRequest)
//                        } else {
//                            SKCache.sharedCache.setImage(image, forKey: self.photoURL)
//                        }
//                    }
//                    DispatchQueue.main.async {
//                        self.underlyingImage = image
//                        self.loadUnderlyingImageComplete()
//                    }
//                }
//
//            })
//            task?.resume()
//    }

    open func loadUnderlyingImageComplete() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: SKPHOTO_LOADING_DID_END_NOTIFICATION), object: self)
    }
    
}

// MARK: - Static Function

extension SKPhoto {
//    public static func photoWithImage(_ image: UIImage) -> SKPhoto {
//        return SKPhoto(image: image)
//    }
//
//    public static func photoWithImageURL(_ url: String) -> SKPhoto {
//        return SKPhoto(url: url)
//    }
//
//    public static func photoWithImageURL(_ url: String, holder: UIImage?) -> SKPhoto {
//        return SKPhoto(url: url, holder: holder)
//    }
    
    public static func fromAsset(_ asset: PHAsset) -> SKPhoto {
        return SKPhoto(asset: asset)
    }
}
