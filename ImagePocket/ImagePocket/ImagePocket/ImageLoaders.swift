//
//  SharedImageLoader.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 11/29/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import Foundation
import Photos

final class ImageLoader {
    
    private init(){
    }
    
    private static var optionsForImage: PHImageRequestOptions = {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        return options
    }()
    
    private static var optionsForVideo: PHVideoRequestOptions = {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .automatic
        options.isNetworkAccessAllowed = true
        return options
    }()
    
    public static func load(asset: PHAsset, onComplete: @escaping (UIImage?) -> Void) -> Void {
        PHImageManager.default().requestImage(for: asset,
                                              targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
                                              contentMode: .aspectFit,
                                              options: optionsForImage,
                                              resultHandler: { image, info in
                                                onComplete(image)
        })
    }
    
    public static func load(asset: PHAsset, onComplete: @escaping (AVPlayerItem?) -> Void) -> Void {
        PHImageManager.default().requestPlayerItem(forVideo: asset, options: optionsForVideo, resultHandler: { playerItem, _ in
            onComplete(playerItem)
        })
    }
}

final class SharedImageLoader {
    
    private let _imageCache = ImageCache.instance
    private var _inProcessRequestIds = [PHImageRequestID]()
    
    public func load(images: [ImageEntity], onComplete: @escaping ([UIImage]) -> Void) -> Void {
        cancel()
        
        if images.isEmpty {
            fatalError("Empty images")
        }
        
        var result = [UIImage]()
        let dispatchGroup = DispatchGroup()
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        for image in images {
            if let asset = _imageCache[image.localIdentifier] {
                
                dispatchGroup.enter()
                let requestId = PHImageManager.default().requestImage(for: asset,
                                                                      targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
                                                                      contentMode: .aspectFit,
                                                                      options: options,
                                                                      resultHandler: {image, _ in
                                                                        if let image = image {
                                                                            result.append(image)
                                                                        }
                                                                        dispatchGroup.leave()
                                                                        
                })
                _inProcessRequestIds.append(requestId)
            }
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main, execute: {
            self._inProcessRequestIds = [PHImageRequestID]()
            onComplete(result)
        })
    }
    
    public func cancel() -> Void {
        if _inProcessRequestIds.isEmpty {
            return
        }
        for requestId  in _inProcessRequestIds {
            PHImageManager.default().cancelImageRequest(requestId)
        }
        _inProcessRequestIds = [PHImageRequestID]()
    }
}
