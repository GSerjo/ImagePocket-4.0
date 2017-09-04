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
    
    private let _tagCache = TagCache.instance
    
    private init(){
        
        _taggedImages = _imageRepository.getAll().toDictionary{$0.localIdentifier}
        
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let fetchResult = PHAsset.fetchAssets(with: allPhotosOptions)
        
        _assets = getAssets(fetchResult).toDictionary{$0.localIdentifier}
        _actualImages  = _assets.values.map(createImage).toDictionary{$0.localIdentifier}
        
        syncImages()
    }
    
    subscript(localId: String) -> PHAsset?{
        return _assets[localId]
    }
    
    func getImages(tag: TagEntity) -> [ImageEntity]{
        
        var result = [ImageEntity]()
        
        if(tag.isAll){
            result = _actualImages.values.toArray()
        }
        else if(tag.isUntagged){
            result = _actualImages.values.toArray()
        }
        
        else if(_taggedImages.isEmpty){
            result = [ImageEntity]()
        }
        else{
            result = Array(_taggedImages.values.filter{$0.id == tag.id})
        }
        result.sort{$0.creationDate ?? Date() > $1.creationDate ?? Date()}
        
        return result
    }
    
    func saveOrUpdate(entities: [ImageEntity]){
        
        entities.forEach{_tagCache.saveOrUpdate(tags: $0.newTags)}
        _imageRepository.saveOrUpdate(entities)
        
        for entity in entities {
            let changes = entity.tagChanges()
            _imageRepository.remove(tagImages: changes.removeIds)
            let tagImages = _imageRepository.addTagImage(imageId: entity.id, entities: changes.add)
            entity.appendTagId(entities: tagImages)
        }
    }
    
    private func syncImages(){
        for image in _taggedImages.values {
            if _actualImages.keys.contains(image.localIdentifier){
                _actualImages[image.localIdentifier] = image
            }
        }
    }
    
    private func getAssets(_ fetchResult: PHFetchResult<PHAsset>) -> [PHAsset]{
        var assets: [PHAsset] = []
        
        fetchResult.enumerateObjects(using: {(object, id, _) in
            assets.append(object)
        })
        
        return assets
    }
    
    private func createImage(asset: PHAsset) -> ImageEntity{
        return ImageEntity(localIdentifier: asset.localIdentifier, creationDate: asset.creationDate)
    }
}

