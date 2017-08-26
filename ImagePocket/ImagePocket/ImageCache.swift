//
//  ImageCache.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 8/20/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import Foundation
import Photos

final class ImageCache{
    
    static let inctace = ImageCache()
    
    private var _assets = [String: PHAsset]()
    private let _imageRepository = ImageRepository.instance
    private var _taggedImages = [String: ImageEntity]()
    private var _actualImages = [String:ImageEntity]()
    
    
    private init(){
        
        _taggedImages = _imageRepository.getAll().toDictionary{$0.localIdentifier}
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: nil)
        _assets = getAssets(fetchResult).toDictionary{$0.localIdentifier}
        _actualImages  = _assets.values.map(createImage).toDictionary{$0.localIdentifier}
    }
    
    subscript(localId: String) -> PHAsset?{
        return _assets[localId]
    }
    
    func getImages(tag: TagEntity) -> [ImageEntity]{
        
        if(tag.isAll){
            return Array(_actualImages.values)
        }
        if(tag.isUntagged){
            return Array(_actualImages.values)
        }
        
        if(_taggedImages.isEmpty){
            return [ImageEntity]()
        }

        let result = _taggedImages.values.filter{$0.id == tag.id}
        
        return Array(result)
    }
    
    private func getAssets(_ fetchResult: PHFetchResult<PHAsset>) -> [PHAsset]{
        var assets: [PHAsset] = []
        
        fetchResult.enumerateObjects({(object, id, _) in
            assets.append(object)
        })
        return assets
    }
    
    private func createImage(asset: PHAsset) -> ImageEntity{
        return ImageEntity(localIdentifier: asset.localIdentifier)
    }
}

