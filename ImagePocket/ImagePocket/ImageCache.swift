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
    
    static let instance = ImageCache()
    
    private var _assets = [String: PHAsset]()
    private let _imageRepository = ImageRepository.instance
    private var _taggedImages = [String: ImageEntity]()
    private var _actualImages = [String:ImageEntity]()
    private let _tagCache = TagCache.instance
    private let _searchCache = SearchCache.instance
    var fetchResult: PHFetchResult<PHAsset>!
    
//    private init(){
//        
//        _taggedImages = _imageRepository.getAll().toDictionary{$0.localIdentifier}
//        
//        let allPhotosOptions = PHFetchOptions()
//        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
//        
//        fetchResult = PHAsset.fetchAssets(with: allPhotosOptions)
//        
//        _assets = getAssets(fetchResult).toDictionary{$0.localIdentifier}
//        _actualImages  = _assets.values.map(createImage).toDictionary{$0.localIdentifier}
//        
//        syncImages()
//    }
    
    subscript(localId: String) -> PHAsset?{
        return _assets[localId]
    }
    
    func start(onComplete: @escaping () -> Void) -> Void {
        DispatchQueue.global().async {[unowned self] in
            self._taggedImages = self._imageRepository.getAll().toDictionary{$0.localIdentifier}
            
            let allPhotosOptions = PHFetchOptions()
            allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            
            self.fetchResult = PHAsset.fetchAssets(with: allPhotosOptions)
            
            self._assets = self.getAssets(self.fetchResult).toDictionary{$0.localIdentifier}
            self._actualImages  = self._assets.values.map(self.createImage).toDictionary{$0.localIdentifier}
            
            self.syncImages()
            
            onComplete()
        }
    }
    
    func reloadImages() -> Void {
        _assets = getAssets(fetchResult).toDictionary{$0.localIdentifier}
        _actualImages  = _assets.values.map(createImage).toDictionary{$0.localIdentifier}
        
        syncImages()
    }
    
    func search(text: String) -> [ImageEntity] {
        if text.isEmpty() {
            return getImages(tag: TagEntity.all)
        }
        
        let terms = text.components(separatedBy: " ").map{$0.trimmingCharacters(in: .whitespacesAndNewlines)}.filter{!$0.isEmpty()}
        
        var result = [ImageEntity]()
        for item in _taggedImages.values {
            
            for searchText in terms {
                if item.hasSearchableText(text: searchText){
                    result.append(item)
                    break
                }
            }
        }

        let searchResult = _searchCache.search(terms)
        result.append(contentsOf: searchResult.flatMap{_actualImages[$0.localIdentifier]})
        
        result = result.distinct()
        result.sort{$0.creationDate ?? Date() > $1.creationDate ?? Date()}
        return result
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
            result = Array(_taggedImages.values.filter{$0.containsTag(tagId: tag.id)})
        }
        result.sort{$0.creationDate ?? Date() > $1.creationDate ?? Date()}
        
        return result
    }
    
    func getImagesAsync(tag: TagEntity, onComplete: @escaping(_ images: [ImageEntity]) -> Void) -> Void {
        DispatchQueue.global().async {[unowned self] in
            let result = self.getImages(tag: tag)
            
            onComplete(result)
        }
    }
    
    func saveOrUpdate(entities: [ImageEntity]) -> Void {
        
        entities.forEach{_tagCache.saveOrUpdate(tags: $0.newTags)}
        let imageChanges = _imageRepository.saveOrUpdate(entities)
        
        imageChanges.add.forEach { item in
            _taggedImages[item.localIdentifier] = item
            _actualImages[item.localIdentifier] = item
//            _actualImages.removeValue(forKey: item.localIdentifier)
        }
        
        imageChanges.remove.forEach{ item in
            _taggedImages.removeValue(forKey: item.localIdentifier)
            _actualImages[item.localIdentifier] = item
        }
        
        for entity in entities {
            let tagChanges = entity.tagChanges()
            _imageRepository.remove(tagImages: tagChanges.removeIds)
            let tagImages = _imageRepository.addTagImage(imageId: entity.id, entities: tagChanges.add)
            entity.appendTagId(entities: tagImages)
        }
    }
    
    private func syncImages() -> Void {
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
        SearchCache.instance.fill(assets: assets)
        return assets
    }
    
    private func createImage(asset: PHAsset) -> ImageEntity{
        return ImageEntity(localIdentifier: asset.localIdentifier, creationDate: asset.creationDate)
    }
}

